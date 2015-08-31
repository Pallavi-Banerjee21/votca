# Introduction #

VOTCA is spitted into different modules, see RepositoryStructure

# Dependencies #
To compile VOTCA modules, you need the header files of all packages below, i.e. the **-dev** packages on Debian/Ubuntu or the **-devel** packages on OpenSuse/Fedora.

## VOTCA Tools ##
VOTCA Tools contains the basic VOTCA classes.

Dependencies:
  * [expat](http://expat.sourceforge.net)
  * [boost](http://www.boost.org)
  * [boost-program-options](http://www.boost.org)
  * [fftw3](http://www.fftw.org) (_shared double precession_ build fftw with `--enable-double --enable-shared`)
  * [doxygen](http://www.doxygen.org) (optional)
  * [sqlite3](http://www.sqlite.org/) (optional)
  * [txt2tags](http://www.txt2tags.org) (optional)
  * [pkg-config](http://pkg-config.freedesktop.org) (or specify everything _by hand_)
  * [gsl](http://www.gnu.org/software/gsl)
  * [blas](http://www.netlib.org/blas/) if gsl comes without its bundled libblas version (gslcblas)
  * [mercurial](http://mercurial.selenic.com/) if you to build the development version

Notes:
  * You can compile VOTCA tools without gsl (add ```-DWITH_GSL=NO```), but this will lead to **reduced functionality**, i.e. csg\_resample does **NOT** support cubic splines and csg\_fmatch from VOTCA csg will **NOT** work at all.
  * You can compile VOTCA tools without fftw3 (add ```-DWITH_FFTW=NO```), but this will lead to **reduced functionality**, i.e. csg\_boltzmann from VOTCA csg will not be able to calculate correlations.
  * sqlite3 is only needed for the charge transport modules, it can be disabled by adding ```-DWITH_SQLITE3=NO```
  * txt2tags is only necessary for manpages
  * doxygen is only necessary for html documentation, which can also be found [here](http://doc.votca.org)

## VOTCA CSG ##
VOTCA CSG the VOTCA coarse-graining engine incl. the iterative framework.
Dependencies:
  * VOTCA Tools (see above)
  * libgmx from the [GroMaCS](http://www.gromacs.org) Package (Version >= 4.0.7, but 4.5 recommended, optional, can be installed by [build.sh](Installing#Gromacs.md))
  * [pkg-config](http://pkg-config.freedesktop.org) (or specify everything _by hand_)

Notes:
  * You can compile VOTCA CSG without libgmx, but this will lead to **reduced functionality**, i.e. program from VOTCA csg will not be able to read gromacs file formats.

Other runtime dependencies used by the iterative framework:
  * bash
  * sed
  * awk
  * octave or matlab (for imc)
  * perl
  * [GroMaCS](http://www.gromacs.org), [ESPResSo](http://www.espressomd.org), [LAMMPS](http://lammps.sandia.gov), [DL\_POLY](http://www.stfc.ac.uk/cse/25526.aspx) or [ESPResSo++](http://www.espresso-pp.de/) as sampling engine


## VOTCA CSG Applications ##
These are simple VOTCA applications based on csg.
Dependencies:
  * [pkg-config](http://pkg-config.freedesktop.org)
  * VOTCA CSG (see above)