dnl
dnl Copyright 1998 - 2004 Double Precision, Inc.  See COPYING for
dnl distribution information.

AC_INIT([liblock-mini],[0.60],[https://gitlab.com/mpsuzuki/couriertls-server/-/issues])

AC_CONFIG_HEADERS([liblock_config.h])
AC_CONFIG_FILES([GNUmakefile])
AM_INIT_AUTOMAKE([foreign])

dnl Checks for programs.
# AC_PROG_AWK
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_RANLIB
# LT_INIT

dnl ------------------------------------------------------------------------
dnl headers
dnl ------------------------------------------------------------------------
# AC_CHECK_HEADERS([dlfcn.h errno.h inttypes.h stdint.h stdio.h stdlib.h string.h strings.h])
AC_CHECK_HEADERS([errno.h])
# AC_CHECK_HEADERS([sysexits.h sys/ioctl.h sys/types.h sys/wait.h])
AC_CHECK_HEADERS([sysexits.h sys/ioctl.h sys/wait.h])

AC_CHECK_HEADERS([sys/file.h fcntl.h sys/fcntl.h])


dnl ------------------------------------------------------------------------
dnl types
dnl ------------------------------------------------------------------------
AC_TYPE_PID_T
if test x"${ac_cv_type_pid_t}" = xyes
then
  AC_DEFINE([HAVE_PID_T],1,[Defined to 1 if 'pid_t' type is available])
fi

dnl ------------------------------------------------------------------------
dnl type for
dnl * partial locking by fcntl(): struct flock.l_start & flock.l_len.
dnl * partial locking by lseek(): type of the 2nd argument "offset".
dnl According to System V Interface Definition Issue 2 Volume 1 (1986) p.76,
dnl & p.101, the early System V used "long" for these variables.
dnl ------------------------------------------------------------------------
AC_TYPE_OFF_T
if test x"${ac_cv_type_off_t}" = xyes
then
  AC_DEFINE([HAVE_OFF_T],1,[Defined to 1 if 'off_t' type is available])
  AC_CHECK_TYPE([off64_t],[
    AC_DEFINE([HAVE_OFF64_T],1,[Defined to 1 if 'off64_t' type is available])
    ll_offset_type=off64_t
  ],[
    ll_offset_type=off_t
  ],[
#if HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif
  ])
else
  ll_offset_type=long
fi
AC_DEFINE_UNQUOTED([LL_OFFSET_TYPE],
                   ${ll_offset_type},
                   [Defined to off64_t if available, otherwise off_t])

dnl ------------------------------------------------------------------------
dnl functions
dnl ------------------------------------------------------------------------
AC_CHECK_FUNCS([getdtablesize setpgrp sysconf],[],[])

dnl ------------------------------------------------------------------------
dnl flock() appeared in 4.2BSD and declared in <sys/file.h>
dnl ------------------------------------------------------------------------
use_flock=no
AC_CHECK_FUNC([flock],[
  AC_CHECK_DECL([flock(int, int)],[
    AC_DEFINE([HAVE_FLOCK],1,[Defined to 1 if flock() is declared by <sys/file.h>])
    use_flock=yes
  ],[],[
#if HAVE_SYS_FILE_H
# include <sys/file.h>
#endif
  ])
],[])

dnl ------------------------------------------------------------------------
dnl According to X/Open System Interface and Headers Issue 4 Volume 2 p.362,
dnl lockf() should be declared in <unistd.h>.
dnl According to System V Interface Definition Issue 2 Volume 1 (1986) p.98,
dnl the 3rd argument was originally typed as "long" in SVR1 and SVR2.
dnl ------------------------------------------------------------------------
use_lockf=no
AC_CHECK_FUNC([lockf],[
  AC_CHECK_DECL([lockf(int, int, off_t)],[
    AC_DEFINE([HAVE_LOCKF],1,[Defineed to 1 if lockf() is declared by <unistd.h>])
    use_lockf=yes
  ],[],[
#if HAVE_UNISTD_H
# include <unistd.h>
#endif
#if HAVE_OFF_T
#else
/* for early System V without "off_t" */ 
typedef long off_t;
#endif
  ])
],[])

dnl ------------------------------------------------------------------------
dnl According to X/Open System Interface and Headers Issue 4 Volume 2 p.176,
dnl fcntl() should be declared in <fcntl.h>. Also <sys/types.h> & <unistd.h>
dnl should be included to use it.
dnl ------------------------------------------------------------------------
AC_DEFUN([AX_FCNTL_HEADERS],[
#if HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif
#if HAVE_UNISTD_H
# include <unistd.h>
#endif
#if HAVE_FCNTL_H
# include <fcntl.h>
#endif
#if HAVE_SYS_FCNTL_H
# include <sys/fcntl.h>
#endif
])


AC_CHECK_FUNC([fcntl],[
  AC_CHECK_DECL([fcntl(int, int, ...)],[
    ac_cv_func_fcntl=yes
    AC_DEFINE([HAVE_FCNTL],1,[Defined to 1 if fcntl() is declared by <unistd.h>])
  ],[
    ac_cv_func_fcntl=no
  ],[AX_FCNTL_HEADERS])
],[])

dnl ------------------------------------------------------------------------
dnl According to System V Interface Definition Issue 2 Volume 1 (1986) p.76,
dnl locking features of fcntl() was added after System V Release 2.0.
dnl For availability check, the macros for locking features and flock_t type
dnl should be tested.
dnl ------------------------------------------------------------------------
use_fcntl=no
if test x"${ac_cv_func_fcntl}" = xyes
then
  AC_CHECK_DECLS([F_SETLK, F_SETLKW, F_RDLCK, F_WRLCK, F_UNLCK],[],[],[AX_FCNTL_HEADERS])
  AC_CHECK_TYPE([flock_t],[
    AC_DEFINE([HAVE_FLOCK_T],1,[Defined to 1 if 'flock_t' type is available])
    use_fcntl=yes
  ],[
    AC_CHECK_MEMBER([struct flock.l_type],[
      use_fcntl=yes
      AC_DEFINE([HAVE_STRUCT_FLOCK],1,[Defined to 1 if 'struct flock' is valid])
    ],[],[AX_FCNTL_HEADERS])
  ],[AX_FCNTL_HEADERS])
fi

dnl ------------------------------------------------------------------------
dnl Testing the compilations of locktest.c
dnl ------------------------------------------------------------------------
if test -d empty
then
  rm -r -f empty
fi
mkdir empty
touch empty/liblock_config.h
orig_CFLAGS="${CFLAGS}"

CFLAGS="${LIBLOCK_CFLAGS} -DUSE_FCNTL -UUSE_FLOCK -UUSE_LOCKF -Iempty ${CFLAGS}"
if test x"${use_fcntl}" = xyes
then
  AC_MSG_CHECKING([locktest.c is compilable for fcntl])
  dnl AC_LINK_IFELSE([AC_LANG_SOURCE([[#include "locktest.c"]])],[
  AC_RUN_IFELSE([AC_LANG_SOURCE([[#include "locktest.c"]])],[
    AC_MSG_RESULT([yes])
  ],[
    AC_MSG_RESULT([no])
    use_fcntl=no
  ],[
    AC_MSG_RESULT([skip])
  ])
fi

CFLAGS="${LIBLOCK_CFLAGS} -UUSE_FCNTL -DUSE_FLOCK -UUSE_LOCKF -Iempty ${CFLAGS}"
if test x"${use_flock}" = xyes
then
  AC_MSG_CHECKING([locktest.c is compilable for flock])
  dnl AC_LINK_IFELSE([AC_LANG_SOURCE([[#include "locktest.c"]])],[
  AC_RUN_IFELSE([AC_LANG_SOURCE([[#include "locktest.c"]])],[
    AC_MSG_RESULT([yes])
  ],[
    AC_MSG_RESULT([no])
    use_flock=no
  ],[
    AC_MSG_RESULT([skip])
  ])
fi


CFLAGS="${LIBLOCK_CFLAGS} -UUSE_FCNTL -UUSE_FLOCK -DUSE_LOCKF -Iempty ${CFLAGS}"
if test x"${use_lockf}" = xyes
then
  AC_MSG_CHECKING([locktest.c is compilable for lockf])
  dnl AC_LINK_IFELSE([AC_LANG_SOURCE([[#include "locktest.c"]])],[
  AC_RUN_IFELSE([AC_LANG_SOURCE([[#include "locktest.c"]])],[
    AC_MSG_RESULT([yes])
  ],[
    AC_MSG_RESULT([no])
    use_lockf=no
  ],[
    AC_MSG_RESULT([skip])
  ])
fi

CFLAGS="${orig_CFLAGS}"
rm -r -f empty

dnl ------------------------------------------------------------------------
dnl select a backend from fcntl(), flock(), or lockf()
dnl ------------------------------------------------------------------------

if test x"${use_fcntl}" = xyes
then
  AC_MSG_WARN([use fcntl() to lock a (part of) file])
  use_flock=no
  use_lockf=no
elif test x"${use_flock}" = xyes
then
  AC_MSG_WARN([use flock() to lock a (part of) file])
  use_fcntl=no
  use_lockf=no
elif test x"${use_lockf}" = xyes
then
  AC_MSG_WARN([use lockf() to lock a (part of) file])
  use_fcntl=no
  use_flock=no
else
  AC_MSG_ERROR([no file locking mechanism is available])
fi

AM_CONDITIONAL([USE_FCNTL],[test x"${use_fcntl}" = xyes])
AM_CONDITIONAL([USE_FLOCK],[test x"${use_flock}" = xyes])
AM_CONDITIONAL([USE_LOCKF],[test x"${use_lockf}" = xyes])

AC_OUTPUT
