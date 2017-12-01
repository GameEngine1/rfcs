- Feature Name: PQConnetor
- Start Date: 2017-12-01
- RFC PR:
- Pony Issue:

# Summary

interface to ease interaction with PostGresql databases

# Motivation

to easily interact with a database using a easy to use interface and commmands that can be easily be extended by using fun ref to execute "execute" with your own pre-fixes, as making tons of callable functions in the package would be confusing to the users, if all the difference was pre-fixed parameters.

PQConnector support the use of interacting with postgres databases. (haven't tested if it works for other databases)

# Detailed design


This is the bulk of the RFC. Explain the design in enough detail for somebody familiar with the language to understand, and for somebody familiar with the compiler to implement. This should get into specifics and corner-cases, and include examples of how the feature is used.

# How We Teach This

What names and terminology work best for these concepts and why? How is this idea best presented? As a continuation of existing Pony patterns, or as a wholly new one?

Would the acceptance of this proposal mean the Pony guides must be re-organized or altered? Does it change how Pony is taught to new users at any level?

How should this feature be introduced and taught to existing Pony users?

# How We Test This

How do we assure that the initial implementation works? How do we assure going forward that the new functionality works after people make changes? Do we need unit tests? Something more sophisticated? What's the scope of testing? Does this change impact the testing of other parts of Pony? Is our standard CI coverage sufficient to test this change? Is manual intervention required?

In general this section should be able to serve as acceptance criteria for any implementation of the RFC.

# Drawbacks

Why should we *not* do this? Things you might want to note:

* Breaks existing code
* Introduces instability into the compiler and or runtime which will result in bugs we are going to spend time tracking down
* Maintenance cost of added code

# Alternatives

What other designs have been considered? What is the impact of not doing this?
None is not an acceptable answer. There is always to option of not implementing the RFC.

# Unresolved questions

What parts of the design are still TBD?
