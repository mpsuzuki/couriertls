#
# Copyright 1998 - 2002 Double Precision, Inc.  See COPYING for
# distribution information.
#


noinst_LTLIBRARIES=liblock.la

if USE_FCNTL
fcntl=lockfcntl.c
else
fcntl=
endif

if USE_FLOCK
flock=lockflock.c
else
flock=
endif

if USE_LOCKF
lockf=locklockf.c
else
lockf=
endif

liblock_la_SOURCES=$(fcntl) $(flock) $(lockf) liblock.h

EXTRA_DIST=lockfcntl.c lockflock.c locklockf.c locktest.c $(noinst_DATA)
