dnl
dnl Copyright 1998 - 2004 Double Precision, Inc.  See COPYING for
dnl distribution information.

rm -f liblock_config.h
AC_INIT([liblock-mini],[0.60],[https://gitlab.com/mpsuzuki/couriertls-server/-/issues])

AC_CONFIG_HEADERS([config.h])
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
dnl On ancient systems without pid_t, AC_TYPE_PID_T() defines "pid_t" as
dnl a preprocessor macro of signed integer.
dnl ------------------------------------------------------------------------
AC_TYPE_PID_T

dnl ------------------------------------------------------------------------
dnl On ancient systems without off_t, AC_TYPE_OFF_T() defines "off_t" as
dnl a preprocessor macro of long integer.
dnl ------------------------------------------------------------------------
AC_SYS_LARGEFILE
AC_TYPE_OFF_T
if test x"${ac_cv_type_off_t}" = xyes
then
  AC_DEFINE([HAVE_OFF_T],1,[Defined to 1 if 'off_t' type is available])
  AC_CHECK_TYPE([off64_t],[
    AC_DEFINE([HAVE_OFF64_T],1,[Defined to 1 if 'off64_t' type is available])
    LL_OFFSET_TYPE=off64_t
  ],[
    LL_OFFSET_TYPE=off_t
  ],[
#if HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif
  ])
else
  LL_OFFSET_TYPE=long
fi
AC_SUBST([LL_OFFSET_TYPE])
AC_CONFIG_FILES([liblock_config.h:liblock_config.h.in])

dnl ------------------------------------------------------------------------
dnl functions
dnl ------------------------------------------------------------------------
AC_CHECK_FUNCS([getdtablesize setpgrp sysconf],[],[])

dnl ------------------------------------------------------------------------
dnl fcntl(), flock(), lockf()
dnl ------------------------------------------------------------------------
AX_CHECK_FCNTL_LOCKING([use_fcntl=yes],[use_fcntl=no])
AX_CHECK_FLOCK([use_flock=yes],[use_flock=no])
AX_CHECK_LOCKF([use_lockf=yes],[use_lockf=no])
AX_LOCKTEST([AC_LANG_SOURCE([[#include "locktest.c"]])],
                            [-DLL_OFFSET_TYPE=${LL_OFFSET_TYPE}],
                            liblock_config.h,
                            use_fcntl, use_flock, use_lockf)

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
