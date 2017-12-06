use "lib:pq"
use "time"
use "signals"
use "collections"
use "debug"
use @pony_asio_event_create[AsioEventID](owner: AsioEventNotify, fd: U32, flags: U32, nsec: U64, noisy: Bool)
use @pony_asio_event_destroy[None](event: AsioEventID)
use @PQsocket[U32](conn: PGconn)
use @PQexec[PGresult](conn: PGconn, query: Pointer[U8] tag)
use @PQconnectdb[PGconn](conn_str:Pointer[U8] tag)
use @PQnotifies[MaybePointer[PGnotify]](conn: PGconn)
use @PQconsumeInput[I32](conn: PGconn)

primitive PGresult
primitive PGconn

struct PGnotify
  var relname: Pointer[U8] = Pointer[U8]
  var be_pid: I32 = -1
  var extra: Pointer[U8] = Pointer[U8]
  new create() => None

interface DBNotify
  fun ref notification_received(notify: String, message:String)
  fun ref connection_lost(s: String)
  fun ref connection_established(s: String): F32

actor PGConnector
// This is what you call and set a let arround to execute commands, example:
// let dbConnect = PGConnector("dbname=nyxia", Foobar(env'))
  var _conn: PGconn
  var _fd: U32
  let _connInfo: String
  var _event: AsioEventID = AsioEventID
  var _count: F32 = 0
  var _ready2send: Bool = false
  var _reconnectIntervals: F32 = 0
  var _subscribedChannels: Set[String] = Set[String]
  var _notifier: DBNotify iso
  var _disposed: Bool = false
  let _reconnTimers: Timers = Timers
  var _reconnectIntervalFn: {(F32): F32} val = { (x: F32): F32 => x }

    new create(connInfo: String, notifier': DBNotify iso) =>
    _notifier = consume notifier'
    _connInfo = connInfo
    _conn = @PQconnectdb((_connInfo).cstring())
    _fd = @PQsocket(_conn)
    this._connect(true)
  
  fun _listen(channel: String):PGresult =>
    @PQexec(_conn, ("listen " + channel).cstring())

  fun _unlisten(channel: String):PGresult =>
    @PQexec(_conn, ("unlisten " + channel).cstring())

  be execute(s: String) =>
// Execute something on the database.
// Execute is safe to call whenever, and will be executed once there is a working connection.
    if _ready2send then
    @PQexec(_conn, (s).cstring())
    else
      let timers = Timers
      let timer = Timer(ExecuteNotReady(this, s), 1_000_000)
      timers(consume timer)
    end

  be reconnect_interval(f: {(F32): F32} val) =>
// Setup the time between reconnection tries by a lambda function in seconds
// Must be above 0
    _reconnectIntervalFn = f

  be reconnect_interval_simple(f: F32) =>
// Setup the time between reconnection tries by a float in seconds
// Must be above 0
    _reconnectIntervalFn = { (x: F32): F32 => f }

  be add_listen(channel: String) =>
// Adds a channel to listen to, does not need to be recalled when losing connection.
    _subscribedChannels = _subscribedChannels.add(channel)
    _listen(channel)

  be remove_listen(channel: String) =>
// Removes a channel that is listened to.
    _unlisten(channel)
    _subscribedChannels = _subscribedChannels.sub(channel)

  be connect() =>
// Call this when you have disposed this, and still has the actor reference to continue.
    this._connect(false)


  be dispose() =>
// Disposes the connection.
// You will still need to terminate the actor
    _ready2send = false
    _disposed = true
    @pony_asio_event_destroy(_event)
    @PQfinish[None](_conn)

be _connect(initial: Bool = false) =>
//this is called by connect() and when initialized.
    if not initial then
      _conn = @PQconnectdb((_connInfo).cstring())
      _fd = @PQsocket(_conn)
      _disposed = false
    end
    let status = @PQstatus[I32](_conn)
    if status != 0 then
      _reconnectIntervals = _reconnectIntervalFn(_count)
      _count = _count + 1
      this._tryConnect(_reconnectIntervals)
    else
      @pony_asio_event_create(this, _fd, AsioEvent.read(), 0, true)
      _reconnectIntervals = _notifier.connection_established(_connInfo)
      for channel in _subscribedChannels.values() do
        _listen(channel)
      end
      _ready2send = true
    end

  be _tryConnect(length: F32 = 1) =>
    _reconnTimers.dispose()
    let timer = Timer(ReconnectTimer(this), ((if length < 0 then -length elseif length == 0 then 0.000_000_000_1 else length end) * 1_000_000_000).u64())
    _reconnTimers(consume timer)

  be _event_notify(event: AsioEventID, flags: U32, arg: U32) =>
    Debug.out(_disposed.string())
    if AsioEvent.disposable(flags) then
      @pony_asio_event_destroy(event)
      return
    end
    var status = @PQconsumeInput(_conn)
    if status != 1 then
      _ready2send = false
      _count = 0
      if not _disposed then
        this._tryConnect(_reconnectIntervalFn(_count))
        _notifier.connection_lost(_connInfo)
      end
    end
    try
      let notify = @PQnotifies(_conn)
      _notifier.notification_received(String.from_cstring(notify()?.relname).string(), String.from_cstring(notify()?.extra).string())
      @PQfreemem[None](notify)
    end

class ReconnectTimer is TimerNotify
  let _acting: PGConnector

  new iso create(acting: PGConnector) =>
    _acting = acting

  fun ref apply(timer: Timer, count: U64): Bool =>
    _acting.connect()
    false

class ExecuteNotReady is TimerNotify
  let _acting: PGConnector
  let _s: String

  new iso create(acting: PGConnector, s: String) =>
    _acting = acting
    _s = s

  fun ref apply(timer: Timer, count: U64): Bool =>
    _acting.execute(_s)
    false
