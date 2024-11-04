dnl ------------------------------------------------------------------------
dnl flock() appeared in 4.2BSD and declared in <sys/file.h>
dnl ------------------------------------------------------------------------
AC_DEFUN([AX_CHECK_FLOCK],[
  ax_cv_check_flock_callable=no
  AC_CHECK_FUNC([flock],[
    AC_CHECK_DECL([flock(int, int)],[
      AC_DEFINE([HAVE_FLOCK],1,[Defined to 1 if flock() is declared by <sys/file.h>])
      ax_cv_check_flock_callable=yes
    ],[],[
#if HAVE_SYS_FILE_H
# include <sys/file.h>
#endif
    ])
  ],[])
  if test x"${ax_cv_check_flock_callable}" = xyes
  then
    [$1]
  else
    [$2]
  fi
])
