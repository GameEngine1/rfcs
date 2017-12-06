- Feature Name: PQConnetor
- Start Date: 2017-12-01
- RFC PR:
- Pony Issue:

# Summary

interface to ease interaction with PostGresql databases

# Motivation

to easily interact with a database using a easy to use interface and commands that can be easily be extended by defining functions to execute "execute" with your own pre-fixes, as making tons of callable functions in the package would be confusing to the users, if the only differences between them are pre-fixed parameters.

PQConnector support the use of interacting with postgres databases. (haven't tested if it works for other databases)

# Detailed design

the design is made to call functions and let it work, after what you got in your interface.

first of all impliment the package with use "PQConnector"

put up your interface, in the example "TestPQConnector.pony" this interface interaction is called "Foobar"
```pony
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
```
after that initiate the interaction with the Database:
```pony
actor Main
  var _env: Env
  let pgConnect: PGConnector
  new create(env': Env) =>
    let dbinfo = "dbname=nyxia"   //{connection info}
    let dbConnect = DBConnector(dbinfo, Foobar(env'))
```
this initiates the connection to the database, and lets you command it
commands are as follows:

```pony
  pgConnect.dispose()         //this removes the timers, and connections but retain the listeners
  pgConnect.connect()     //we only call this because of dispose(), normally it is initialized when you create it
  pgConnect.reconnect_interval_simple(F32(1)) // sets the reconnection time to 1 second (default is 1 second anyways)
  pgConnect.add_listen("bar") //adds "bar" as a listener that the foobar will be getting
  pgConnect.execute("notify bar, 'shouldn't show up")
  pgConnect.reconnect_interval(reconnectIntervalFn)
```
sets the reconnection interval to a lambda function

This is the bulk of the RFC. Explain the design in enough detail for somebody familiar with the language to understand, and for somebody familiar with the compiler to implement. This should get into specifics and corner-cases, and include examples of how the feature is used.

# How We Teach This

Catagory: "Package exploration" - Name: "Easy PostGres interaction with Pony".

PQConnector simplifies the usage of "lib:pq".

It doesn't alter anything existing in Pony, but it adds an optional package, which has documentation comments and an example that shows everything that you would need to be able to use the package.

this feature can be found in packages and doesn't nessecerily need to be taught to the general users of Pony, but it would be appreciated to have a mention, somewhere, as well as redirected towards it, if anyone asks on the IRC about using Pony for PostGres

I also made an example which can teach people how to use the package. example name: PGexample.pony

# How We Test This

the "TestPQConnector.pony" is an test or an example, setup a database in PostGres name it what you want, change the dbinfo to call the information needed to connect to your database (dbname={name} is enough if you are running a local server) and compile it, then run it, the terminal should output:

```
addlisten bar
connection established: {dbinfo} //might show up a little earlier or later
disposing
notify should after reconn
reconnection
addlisten testing
notify bar
notify testing
removelisten testing
notify shouldn't show up
connection established: {dbinfo} //might show up a little earlier
notification recieved: "foo" from bar
notification recieved: "should show up after reconnection" from bar

```

if it looks like that (the {dbinfo} is what you inputed into the PQConnector) the package is working correctly.

# Drawbacks

you have to have a PostGres server open somewhere which you can connect to, to test this package, but it would be pretty simple, and unless you break Lib:pq, i should be able to maintain it.

# Alternatives

Alternatively I could put it up on github and people would download it and put it into their Package Folder themselves.

# Unresolved questions

Should the package should be called "PGinterface" instead of "PGConnector"?

should "dispose()" should be called "finished()" for PostGresql habits?

should "dispose()" should be called "disconnect()" as you can choose to reconnect it?
