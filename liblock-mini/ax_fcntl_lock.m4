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

AC_DEFUN([AX_CHECK_FCNTL_LOCKING],[
  AC_CHECK_HEADERS([fcntl.h sys/fcntl.h])

  AC_CHECK_FUNC([fcntl],[
    AC_CHECK_DECL([fcntl(int, int, ...)],[
      ax_cv_check_fcntl_callable=yes
      AC_DEFINE([HAVE_FCNTL],1,[Defined to 1 if fcntl() is declared by <unistd.h>])
   ],[
      ax_cv_check_fcntl_callable=no
    ],[AX_FCNTL_HEADERS])
  ],[])

  dnl ------------------------------------------------------------------------
  dnl According to System V Interface Definition Issue 2 Volume 1 (1986) p.76,
  dnl locking features of fcntl() was added after System V Release 2.0.
  dnl For availability check, the macros for locking features and flock_t type
  dnl should be tested.
  dnl ------------------------------------------------------------------------
  ax_cv_check_fcntl_locking_macro=no
  if test x"${ax_cv_check_fcntl_callable}" = xyes
  then
    AC_CHECK_DECLS([F_SETLK, F_SETLKW, F_RDLCK, F_WRLCK, F_UNLCK],[
      ax_cv_check_fcntl_locking_macro=yes
    ],[],[AX_FCNTL_HEADERS])
    AC_CHECK_TYPE([flock_t],[
      AC_DEFINE([HAVE_FLOCK_T],1,[Defined to 1 if 'flock_t' type is available])
    ],[
      AC_CHECK_MEMBER([struct flock.l_type],[
        AC_DEFINE([HAVE_STRUCT_FLOCK],1,[Defined to 1 if 'struct flock' is valid])
      ],[],[AX_FCNTL_HEADERS])
    ],[AX_FCNTL_HEADERS])
  fi
  if test x"${ax_cv_check_fcntl_locking_macro}" = xyes
  then
    [$1]
  else
    [$2]
  fi
])
