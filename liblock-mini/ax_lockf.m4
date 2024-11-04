dnl ------------------------------------------------------------------------
dnl According to X/Open System Interface and Headers Issue 4 Volume 2 p.362,
dnl lockf() should be declared in <unistd.h>.
dnl According to System V Interface Definition Issue 2 Volume 1 (1986) p.98,
dnl the 3rd argument was originally typed as "long" in SVR1 and SVR2.
dnl ------------------------------------------------------------------------
AC_DEFUN([AX_CHECK_LOCKF],[
  ax_cv_check_lockf_callable=no
  AC_CHECK_FUNC([lockf],[
    AC_CHECK_DECL([lockf(int, int, off_t)],[
      AC_DEFINE([HAVE_LOCKF],1,[Defineed to 1 if lockf() is declared by <unistd.h>])
      ax_cv_check_lockf_callable=yes
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
  if test x"${ax_cv_check_lockf_callable}" = xyes
  then
    [$1]
  else
    [$2]
  fi
])
