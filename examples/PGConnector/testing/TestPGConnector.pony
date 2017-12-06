use "../../packages/PGConnector"
use "time"

class Foobar is DBNotify
  var _env: Env
  new iso create(env': Env) =>
    _env = env'
  fun ref notification_received(n: String, m: String) =>
    _env.out.print("notification recieved: \"" + m + "\" from " + n)

  fun ref connection_established(s: String): F32=>
    _env.out.print("connection established: " + s)
    0
  fun ref connection_lost(s: String)=>
    _env.out.print("connection lost: " + s)

actor Main
  var _env: Env
  let pgConnect: PGConnector
  new create(env': Env) =>
    _env = env'
    let array = recover val [F32(2); F32(2); F32(2); F32(2); F32(2); F32(2); F32(2); F32(2); F32(2); F32(5); F32(10)] end
    let reconnectIntervalFn = { (x: F32): F32 => 
      var y = F32(0) 
      if x > 10 then 
        y = 15 
      else 
        y = try array(x.usize())? else 10 end
      end 
      _env.out.print(x.string() + "  -  " + y.string()) 
      y
    } val

    let dbinfo = "dbname=nyxia"
    pgConnect = PGConnector(dbinfo, Foobar(env'))
//reconnect_interval_simple sets the interval to reconnect to a simple float
    pgConnect.reconnect_interval_simple(F32(1))
    //start of, only called to test dispose()
    pgConnect.add_listen("bar")
    _env.out.print("addlisten bar")
    delayCommand({() => pgConnect.dispose();
     _env.out.print("disposing")}, 1)
    delayCommand({() => pgConnect.execute("notify bar, 'should show up after reconnection'");
      _env.out.print("notify should after reconn")}, 2)
    delayCommand({() => pgConnect.connect();
      _env.out.print("reconnection")}, 3)
    //end of, only called to test dispose()
//reconnect_interval_simple sets the interval to reconnect to a lambda function
    delayCommand({() => pgConnect.reconnect_interval(reconnectIntervalFn)}, 4)
//adds listeners that will be inputs of notification_recieved
    delayCommand({() => pgConnect.add_listen("foobar"); /*don't need to listen to foobar again as it remembers from before the dispose*/ 
    pgConnect.add_listen("testing");
    _env.out.print("addlisten testing")}, 5)
//uses execute to test the notifier with postgres function: notify
    delayCommand({() => pgConnect.execute("notify bar, 'foo'");
    _env.out.print("notify bar")}, 6)
    delayCommand({() => pgConnect.execute("notify testing, 'might show up'"); 
    _env.out.print("notify testing")}, 7)
//removing a listener, at the same scope as executing a notify soes in most cases not show up the notifiesl
    delayCommand({() => pgConnect.remove_listen("testing"); 
    _env.out.print("removelisten testing")}, 8)
    delayCommand({() => pgConnect.execute("notify testing, 'removed listener should not show up");
      _env.out.print("notify shouldn't show up")}, 9)
    

    fun ref delayCommand(act: {(): None} val, time: U64) =>
      let timers = Timers
      let timer = Timer(DelayCommand(act), 100_000_000 * time)
      timers(consume timer)


class DelayCommand is TimerNotify
  let _acting: {(): None} val

  new iso create(acting: {(): None} val) =>
    _acting = acting

  fun ref apply(timer: Timer, count: U64): Bool =>
    _acting()
    false