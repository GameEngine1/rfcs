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

```pony
actor PGConnector

  [variables ...]

    new create(connInfo: String, notifier': DBNotify iso) =>
    _notifier = consume notifier'
    _connInfo = connInfo
    _conn = @PQconnectdb((_connInfo).cstring())
    _fd = @PQsocket(_conn)
    this.connect()
```
This is what you call and set a let arround to execute commands.
this initiates the connection to the database, and lets you command it

lets look at that last line, ``this.connect()``:
```pony
be connect(initial: Bool = true) =>
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
```
at first
```pony
    if not initial then
      _conn = @PQconnectdb((_connInfo).cstring())
      _fd = @PQsocket(_conn)
      _disposed = false
    end
```
this connects the database if it's not the first call (as the connection has already been setup)
```pony
    let status = @PQstatus[I32](_conn)
    if status != 0 then
```
checks the status of the connection
```pony
       _reconnectIntervals = _reconnectIntervalFn(_count)
       _count = _count + 1
       this._tryConnect(_reconnectIntervals)
```
if it isn't connected it reads connection interval, increases count and creates a timer that will call this function again after interval in seconds
```pony
@pony_asio_event_create(this, _fd, AsioEvent.read(), 0, true)
      _reconnectIntervals = _notifier.connection_established(_connInfo)
      for channel in _subscribedChannels.values() do
        _listen(channel)
      end
      _ready2send = true
```
if it is connected, it sends a notification that it has connected with the conninfo.
and listens to all listeners added, then sets a Bool that determins that it can send via the execute command. //as it would be have bad glitches without it
    
the behaviors and functions is pretty self-explainatory, and if that's not enough there is comments in them explaining what it does, and what you use it for.

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
