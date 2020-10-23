# Programming for a mind at ease

* Functional Core, Imperative Shell
* Handle data separately from control flow, as in different scope, strive for the boundary to be at least function.
* Handling error should be handled at least in separate functions from data handling.
* Go for historic or multivalued when possible instead of mutation.
* Strive for idempotence in your data and data manipulation.
* Make tracking evolving data possible on a whim

* Separate multiple kinds of data:
  - Raw data
  - Calculated data (from raw data, can always be retrieved from it)
  - History data (evolution of raw data, allows to restore it)

* What's the lifecyle of the data ?

* Minimize the depth of your data structure:
   - deep means less confidance in applying change
   - deep means we either need more experience with the data, or hold more inside our head.
