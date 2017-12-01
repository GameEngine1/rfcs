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
This is the bulk of the RFC. Explain the design in enough detail for somebody familiar with the language to understand, and for somebody familiar with the compiler to implement. This should get into specifics and corner-cases, and include examples of how the feature is used.

# How We Teach This

Catagory: "Package exploration" - Name: "Easy PostGres interaction with Pony".
PQConnector simplifies the usage of "lib:pq".

It doesn't alter anything existing in Pony, but it adds an optional package, which has documentation comments and an example that shows everything that you would need to be able to use the package.

How should this feature be introduced and taught to existing Pony users?
this feature can be found in packages and doesn't nessecerily need to be taught to the general users of Pony, but it would be appreciated to have a mention, somewhere, as well as redirected towards it, if anyone asks on the IRC about using Pony for PostGres

# How We Test This

the "TestPQConnector.pony" is an example that doubles as a tester, setup a database in PostGres name it what you want, change the dbinfo to call the information needed to connect to your database (dbname={name} is enough if you are running a local server) and compile it, then run it, the terminal should output:

```
connection established: {dbinfo}

connection established: {dbinfo}

notification recieved: "test" from testing

notification recieved: " 222" from testing
```

if it looks like that (the {dbinfo} is what you inputed into the PQConnector) the package is working correctly.

# Drawbacks

you have to have a PostGres server open somewhere which you can connect to, to test this package, but it should be pretty simply, and unless you break Lib:pq, i should be able to maintain it.

# Alternatives

Alternatively I could put it up on github and people would download it and put it into their Package Folder themselves. 

# Unresolved questions

rether or not the package should be called "PQinterface" instead of "PQConnector".

rether or not "dispose()" should be called "finished()" for PostGresql habits.

rether or not "dispose()" should be called "destroy()" for what it does to the asio_event.
