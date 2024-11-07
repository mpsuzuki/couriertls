dnl ---------------------------------------------------------
dnl In many cases, pkg-config .pc file does not give "-R" or
dnl "-rpath" option to --libs, even if the library is installed
dnl into the directory which runtime linker does not search by
dnl default. When a default (dynamic) link is failed, retry with
dnl -Wl,-rpath=`pkg-config --variable=libdir xxx`.
dnl
dnl PREREQ:
dnl	a) package must be confirmed to be available
dnl	b) CFLAGS and LIBS are already modified to include the
dnl	   pkg-config --cflags & --libs values
dnl	c) compiler should accept GCC-like "-Wl,-rpath" option
dnl
dnl ---------------------------------------------------------

AC_DEFUN([AX_CHECK_PKG_LIBS_NEEDS_RPATH],[
  ax_chk_pkg_rpath_retry=no
  ax_chk_pkg_rpath=""
  ax_chk_pkg_rpath_orig_libs="${LIBS}"

  if test `${PKG_CONFIG} --print-variables $1 | sed -n '/^libdir$/p' | wc -l` -gt 0
  then
    ax_chk_pkg_libdir=`${PKG_CONFIG} --variable=libdir $1`
    if test x"${ax_chk_pkg_libdir}" != x
    then
      ax_chk_pkg_rpath="-Wl,-rpath=${ax_chk_pkg_libdir}"
    fi
  elif test `${PKG_CONFIG} --print-variables $1 | sed -n '/^prefix$/p' | wc -l` -gt 0
  then
    ax_chk_pkg_prefix=`${PKG_CONFIG} --variable=prefix $1`
    if test x"${ax_chk_pkg_prefix}" != x -a -d ${ax_chk_pkg_prefix}/lib
    then
      ax_chk_pkg_rpath="-Wl,-rpath=${ax_chk_pkg_prefix}/lib"
    fi
  elif test`${PKG_CONFIG} --libs-only-L $1 | sed -n '/^-L/p' | wc -l` -gt 0
  then
    ax_chk_pkg_rpath="-Wl,-rpath="`${PKG_CONFIG} --libs-only-L $1 | sed 's/-L//g' | tr ' \t' '::'`
  fi

  if test x"${ax_chk_pkg_rpath}" != x
  then
    LIBS="${LIBS} ${ax_chk_pkg_rpath}"
    AC_LINK_IFELSE([$2],[ax_chk_pkg_rpath_retry=yes],[])
  fi

  LIBS="${ax_chk_pkg_rpath_orig_libs}"

  if test x"${ax_chk_pkg_rpath_retry}" = xyes
  then
    $3
  else
    $4
  fi
])
