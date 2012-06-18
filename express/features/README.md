Overview
==============

These tests can be run against a production or OpenShift Origin instance for
verification of basic functionality.  These tests should be operating system
independent and will shell out to execute the 'rhc *' commands to emulate a
user as closely as possible.

Pre-conditions
--------------

Primarily, these tests will be run with an existing, pre-created user.  The
tests should keep the resource needs of that user to a minimum, but in some
cases, the user might need to have an increased number of gears added to
support certain tests.

You use environment variables to notify the tests of the well defined user,
password and namespace.  This can be done by putting a block like the following
in your ~/.bashrc file:

    export RHC_RHLOGIN='mylogin@example.com'
    export RHC_PWD='supersecretpassword'
    export RHC_NAMESPACE='mynamespace'

If you do not supply this information, the tests will assume you have setup an
unauthenticated environment and will try and create unique domains and
application using a pre-canned password.

Post-conditions
--------------

It is also your responsibility to clean up after the tests have run.  Currently,
the tests keep all operations on a single application called 'test'.  If you are
using the environment variables to export the RHC information, a handy one line
cleanup command is:

    rhc app destroy -a test -p $RHC_PWD -b; rm -rf /tmp/rhc/
