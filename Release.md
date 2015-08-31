# Introduction #

This is a small guide on how to make a release.

# Major release #
something like 1.2 -> 1.3

  * Check for open issues
  * Update [changelog-csg](http://www.votca.org/development/changelog-csg) and [changelog-ctp](http://www.votca.org/development/changelog-ctp), see
```
hg log -r "release_1.2..default and not branch(stable) and not merge()"
```
  * Checkout default branch: `hg up default`
  * Merge stable into default if not already done: `hg merge stable`
  * Checkout stable branch: `hg up stable`
  * Merge default into stable: `hg merge default`
  * run testsuite
  * test build on AIX and Mac OS
  * test if manual has documentation for all xml options
  * run make\_release.sh from the admin repository
  * upload tarballs and mark them 'featured'
  * update reference file on www.votca.org using `make upload` in the manual
  * send email to the mailing list
  * add a news item to www.votca.org
  * send email to the distribution packager
  * Increase version number in the default branch
  * Mark old tarball 'obsolete' on googlecode
  * Move remaining open issue to the next release
  * Remove issue tag for the old release

# Bugfix release #
something line 1.2 -> 1.2.1
  * Checkout stable branch: `hg up stable`
  * Update [changelog-csg](http://www.votca.org/development/changelog-csg) and [changelog-ctp](http://www.votca.org/development/changelog-ctp), see
```
hg log -r release_1.2..stable
```
  * run testsuite
  * test build on AIX and Mac OS
  * test if manual has changed and build it
  * run make\_release.sh from the admin repository
  * upload tarballs and mark them 'featured'
  * update reference file on www.votca.org if needed
  * send email to the mailing list
  * add a news item to www.votca.org
  * send email to the distribution packager
  * Mark old tarball 'obsolete' on googlecode