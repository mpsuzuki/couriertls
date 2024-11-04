dnl ------------------------------------------------------------------------
dnl Testing the compilations of locktest.c
dnl $1: AC_LANG_SOURCE([[#include "locktest.c"]])
dnl $2: use_fcntl
dnl $3: use_flock
dnl $4: use_lockf
dnl ------------------------------------------------------------------------

AC_DEFUN([AX_LOCKTEST],[
  if test -d empty
  then
    rm -r -f empty
  fi
  mkdir empty
  touch empty/config.h
  orig_CFLAGS="${CFLAGS}"

  CFLAGS="${LIBLOCK_CFLAGS} -DUSE_FCNTL -UUSE_FLOCK -UUSE_LOCKF -Iempty ${CFLAGS}"
  if test x"$$2" = xyes
  then
    AC_MSG_CHECKING([lock testing code is compilable for fcntl])
    AC_RUN_IFELSE([$1],[
      AC_MSG_RESULT([yes])
    ],[
      AC_MSG_RESULT([no])
      $2=no
    ],[
      AC_MSG_RESULT([skip])
    ])
  fi

  CFLAGS="${LIBLOCK_CFLAGS} -UUSE_FCNTL -DUSE_FLOCK -UUSE_LOCKF -Iempty ${CFLAGS}"
  if test x"$$3" = xyes
  then
    AC_MSG_CHECKING([lock testing code is compilable for flock])
    AC_RUN_IFELSE([$1],[
      AC_MSG_RESULT([yes])
    ],[
      AC_MSG_RESULT([no])
      $3=no
    ],[
      AC_MSG_RESULT([skip])
    ])
  fi


  CFLAGS="${LIBLOCK_CFLAGS} -UUSE_FCNTL -UUSE_FLOCK -DUSE_LOCKF -Iempty ${CFLAGS}"
  if test x"$$4" = xyes
  then
    AC_MSG_CHECKING([lock testing code is compilable for lockf])
    AC_RUN_IFELSE([$1],[
      AC_MSG_RESULT([yes])
    ],[
      AC_MSG_RESULT([no])
      $4=no
    ],[
      AC_MSG_RESULT([skip])
    ])
  fi

  CFLAGS="${orig_CFLAGS}"
  rm -r -f empty
])
