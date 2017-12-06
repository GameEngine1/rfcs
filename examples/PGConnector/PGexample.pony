use "../../packages/PGConnector"
use "debug"
class Foobar is DBNotify
  var _env: Env
  let _main: Main
  new iso create(env': Env, main: Main) =>
    _env = env'
    _main = consume main
  fun ref notification_received(n: String, m: String) =>
    match n
      | "testing" => 
        match m
          | "example" => _main.example()
          | "close connections" => _main.close()
        else 
          _env.out.print(n + " had this command: " + m) 
        end
    else
      _env.out.print("notification recieved: \"" + m + "\" from " + n)
    end

  fun ref connection_established(s: String): F32=>
    _env.out.print("connection established: " + s)
    0
  fun ref connection_lost(s: String)=>
    Debug.out("connection lost: " + s)

actor Main
  var _env: Env
  let pgConnect: PGConnector
  new create(env': Env) =>
    _env = env'
    let array = recover val [F32(5); F32(5); F32(10.6); F32(25); F32(60)] end
    let reconnectIntervalFn = { (x: F32): F32 => 
      var y = F32(0) 
      if x >= 5 then 
        y = try array((x%5).usize())? else 10 end
      else 
        y = ((x%5))
      end
        Debug.out(x.string() + " - " + y.string()) 
      y
    } val

    let dbinfo = "dbname=nyxia"
    pgConnect = PGConnector(dbinfo, Foobar(env', this))
//reconnect_interval_simple sets the interval to reconnect to a simple float in seconds
    pgConnect.reconnect_interval_simple(F32(-1))
//reconnect_interval_simple sets the interval to reconnect to a lambda function in seconds
    pgConnect.reconnect_interval(reconnectIntervalFn)
//adds listeners that will be inputs of notification_recieved
    pgConnect.add_listen("bar")
    pgConnect.add_listen("testing")
    pgConnect.add_listen("remove")
//uses execute to test the notifier with postgres function: notify
    pgConnect.execute("notify bar, 'foo'")
    pgConnect.execute("notify testing, 'you can use different listeners to make it do different commands'")
//removing a listener, at the same scope as executing a notify soes in most cases not show up the notifiesl
    pgConnect.remove_listen("remove")
    pgConnect.execute("notify remove, 'removed listeners should not show up")
    pgConnect.execute("notify testing, 'example'")

    be example() =>
      pgConnect.dispose()
      Debug.out("reconnect")
      pgConnect.connect()

    be close() =>
      pgConnect.dispose()
