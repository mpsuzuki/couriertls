dnl ------------------------------------------------------------------------
dnl Testing the compilations of locktest.c
dnl $1: AC_LANG_SOURCE([[#include "locktest.c"]])
dnl $2: CFLAGS
dnl $3: liblock_config.h /* an empty file would be created at empty/$3 */
dnl $4: use_fcntl
dnl $5: use_flock
dnl $6: use_lockf
dnl ------------------------------------------------------------------------

AC_DEFUN([AX_LOCKTEST],[
  if test -d empty
  then
    rm -r -f empty
  fi
  mkdir empty
  touch empty/$3
  orig_CFLAGS="${CFLAGS}"

  CFLAGS="$2 -DUSE_FCNTL -UUSE_FLOCK -UUSE_LOCKF -I${srcdir} -Iempty ${CFLAGS}"
  if test x"$$4" = xyes
  then
    AC_MSG_CHECKING([lock testing code is compilable for fcntl])
    AC_RUN_IFELSE([$1],[
      AC_MSG_RESULT([yes])
    ],[
      AC_MSG_RESULT([no])
      $4=no
    ],[
      AC_MSG_RESULT([skip])
    ])
  fi

  CFLAGS="$2 -UUSE_FCNTL -DUSE_FLOCK -UUSE_LOCKF -I${srcdir} -Iempty ${CFLAGS}"
  if test x"$$5" = xyes
  then
    AC_MSG_CHECKING([lock testing code is compilable for flock])
    AC_RUN_IFELSE([$1],[
      AC_MSG_RESULT([yes])
    ],[
      AC_MSG_RESULT([no])
      $5=no
    ],[
      AC_MSG_RESULT([skip])
    ])
  fi


  CFLAGS="$2 -UUSE_FCNTL -UUSE_FLOCK -DUSE_LOCKF -I${srcdir} -Iempty ${CFLAGS}"
  if test x"$$6" = xyes
  then
    AC_MSG_CHECKING([lock testing code is compilable for lockf])
    AC_RUN_IFELSE([$1],[
      AC_MSG_RESULT([yes])
    ],[
      AC_MSG_RESULT([no])
      $6=no
    ],[
      AC_MSG_RESULT([skip])
    ])
  fi

  CFLAGS="${orig_CFLAGS}"
  rm -r -f empty
])
