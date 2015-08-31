# What is a bug fix? #
A bug fix is a change, which corrects for something, but do **not** add new features.

# Fixes in the stable release #
From time to time there are bugs in the stable release. These possible also needed to be added to the development (default) branch as well

# How to #

  * Checkout the stable branch (if bug exist in the stable release as well): `hg update stable`
  * Fix the bug
    * Possibly a user has exported a changeset, so import it: `hg import file`
    * Possibly a user send a patch, so apply it: `patch -p1 <file.patch`
  * Commit the change: `hg commit -m "bla bla (fixed issue #XXX)`. The string 'fixed issue #XXX` will prompt googlecode to close the issue with number XXX.
  * Merge it into the default branch
    * `hg update default`
    * `hg merge stable`
    * Possibly fix conflicts
      * `edit file`
      * `hg resolve -m file`
    * `hg commit -m "merge with stable"`
    * `hg push`


# Contribute a bug fix #

Make sure your username is corrent in `~/.hgrc`, by looking for a lines like:
```
[ui]
username = Firstname Lastname <abc@def.org>
```

If you have not done it already, checkout the source and go there:

```
hg clone  https://code.google.com/p/votca.csg/ csg
cd csg
```

Fix the bug and have a look at your changes with `hg diff`.

Commit your change and create a patch out of it:

```
hg commit
hg export -r -1 -o mychanges.patch
```

Send mychanges.patch to devs@votca.org