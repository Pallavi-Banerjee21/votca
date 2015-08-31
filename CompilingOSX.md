# Installing VOTCA 1.2.4 on Mac OS X (10.8 or later) #

For the installation on Mac OS X we need first to download and install Xcode Command Line tools:
```
xcode-select --install
```

Then make sure **gsl**, **fftw3** and **cmake** are installed on the system.

**gsl**: Get a copy of gsl-1.16 from http://ftp.heanet.ie/mirrors/gnu/gsl/ and extract:

```
tar -xzvf gsl-1.16.tar.gz 
./configure --enable-shared --prefix=/usr/local/gsl CC=clang CFLAGS="-O3 -arch x86_64"
make
sudo make install 
```

Please note, to install to the folder /usr/local/ on your system you have to get a root access to this location.

**fftw3**: Installing from source:

```
curl -O http://fftw.org/fftw-3.3.4.tar.gz
tar xzvf fftw-3.3.4.tar.gz 
cd fftw-3.3.4
./configure --prefix=/usr/local/fftw --enable-threads CC=clang CFLAGS="-O3 -std=c99 -funroll-loops -mavx -march=native -ffast-math"
make
sudo make install
```

Further we recommend you to install CMake from the binary package available on http://www.cmake.org/files/v3.2/cmake-3.2.2-Darwin-x86_64.dmg

Next we need to download and install the latest version of the Boost library available on http://sourceforge.net/projects/boost/files/latest/download?source=files (at the time of writing it was 1.58.0)

```
tar xzvf boost_1_58_0.tar.gz
cd boost_1_58_0/
./bootstrap.sh --prefix=/usr/local/boost --with-libraries=filesystem,system,date_time,program_options
sudo ./b2 -j2 toolset=clang cxxflags="-arch x86_64" variant=release link=shared install
```

Then edit you ~/.bash\_profile and add the following line at the end of the file:
```
export BOOST_ROOT=/usr/local/boost
```

Now we are almost done with prerequisites. In order to use build.sh script for automatic download and compilation we need, however, either Mercurial (http://mercurial.selenic.com/downloads) or wget tool to be installed. We highly recommend the former, since you don’t need to mess with openssl and other libs required for the later one.

At this point we can start building VOTCA with minimal dependicies:

```
prefix=WHERE/TO/INSTALL/VOTCA
mkdir -p ${prefix}/src
cd ${prefix}/src
curl -O http://votca.googlecode.com/hg/build.sh
chmod +x build.sh
./build.sh --prefix ${prefix} —minimal -DWITH_FFTW=ON -DWITH_GSL=ON -DGSL_INCLUDE_DIR=/usr/local/gsl/include -DGSL_LIBRARY=/usr/local/gsl/lib/libgsl.dylib -DCBLAS_LIBRARY=/usr/local/gsl/lib/libgslcblas.dylib -DFFTW3_INCLUDE_DIR=/usr/local/fftw/include -DFFTW3_LIBRARY=/usr/local/fftw/lib/libfftw3.dylib tools csg
```

Then add the VOTCA install directory to  your ~/.bash\_profile file

```
source path/to/votca/installation/bin/VOTCARC.bash
```

and source it to be able to start with VOTCA tools right away.