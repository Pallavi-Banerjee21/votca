# Introduction #
The build system of the manual is bit complicated, feel free to improve it.

# Building the manual #
Install LaTeX and the [TikZ](http://sourceforge.net/projects/pgf/) package, first. Then you can do:
```
hg clone https://code.google.com/p/votca.csg-manual/ csg-manual
cd csg-manual
source /path/to/votca/bin/VOTCARC.bash
make
```

# Contributing a change #
If you have not done it already, checkout the manual and go there:
```
hg clone  https://code.google.com/p/votca.manual/ csg-manual
cd csg-manual
```
Change the important tex files and have a look at your changes with `hg diff`.

Commit your change and create a patch out of it:
```
hg commit
hg export -r -1 -o mychanges.patch
```
Send mychanges.patch to devs@votca.org