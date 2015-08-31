VOTCA consists of different modules. Each of these modules has an own mercurial repository containing individual tags and branches folders. The different modules are separated in this way due to the fact that they have individual development cycles. Current modules are:

  * **default** - contains the VOTCA builtutil, a script to build all part of VOTCA.
  * **tools** - contains the VOTCA tools, the basic library .
  * **csg** - contains the VOTCA coarse-graining engine incl. the iterative framework.
  * **csgapps** - contains simple VOTCA applications based on csg.
  * **csg-tutorials** - contains simple examples for VOTCA csg.

Some modules contain different branches:

  * **default** - is the main development branch
  * **stable** - contains only bug fixes on top of the last release