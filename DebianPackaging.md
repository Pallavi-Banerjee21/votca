# Prerequisite #

  * Have an account with commit right to debichem on   https://alioth.debian.org/

# Setup #

  * `export devroot=$HOME/development`
  * `mkdir $devroot`
  * `sudo apt-get install svn-buildpackage`
  * `cd $devroot`
  * `mkdir debichem`
  * `svn checkout svn+ssh://<USER>@svn.debian.org/svn/debichem/unstable`
> > `<USER>` is the account name of alioth, usually something like `XXX-guest`
  * Create `~/.svn-buildpackage.conf` with content:
```
svn-override=<devroot>/$PACKAGE
svn-override=<devroot>/$PACKAGE
```


> but replace `<devroot>` with the above value.
  * export DEBEMAIL=junghans@votca.org
  * `mkdir $devroot/votca-tools`

# Update #
  * `cd ${devroot}/debichem/unstable/votca-tools`
  * `uscan --destdir $devroot`
  * drop patches
  * `dch -v VERSION`