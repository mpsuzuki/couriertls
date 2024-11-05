dnl ----------------------------------------------------------
dnl AX_CHECK_RANDOM_SOURCE()
dnl $1: macro name to be defined in config.h and to be substituted in Makefile.am
dnl
AC_DEFUN([AX_CHECK_RANDOM_SOURCE],[
  # Checks for random device
  AC_ARG_WITH(random_device,
  [  --with-random-device=<pathname_to_read_random>	/dev/urandom, /dev/random, or named socket to EGD/PRNG],
  [
    case $withval in
    \".*\")
      ax_random_device=$withval
      ;;
    *)
      ax_random_device=\"$withval\"
      ;;
    esac
  ])

  if test x"${cross_compiling}" = xyes -a x"${ax_random_device}" = x
  then
    AC_MSG_ERROR([In cross compilation, you must specify --with-random-device=<random_device_pathname>])
  elif test x"${ax_random_device}" = x
  then
    AC_CHECK_FILES([/dev/urandom],[
      ax_have__dev_urandom=yes
      AC_DEFINE([HAVE__DEV_RANDOM],1,[Defined to 1 if /dev/urandom is available])
    ],[])
    AC_CHECK_FILES([/dev/random],[
      ax_have__dev_random=yes
      AC_DEFINE([HAVE__DEV_RANDOM],1,[Defined to 1 if /dev/random is available])
    ],[])
  fi

  if test x"${ax_random_device}" != x
  then
    AC_MSG_WARN(${ax_random_device} would be used as the random device)
  elif test x"${ax_have__dev_urandom}" = xyes -a x"${ax_have__dev_random}" = xyes
  then
    # POSIX allows /dev/random and /dev/urandom use different algorithms suitable for their purposes.
    # a) /dev/random is more random, but may be slow and read() may be blocked.
    # b) /dev/urandom is less random, but may be fast and read() would not be blocked.
    # In some systems, like FreeBSD, urandom is a symbolic link to random.
    case "${host_os}" in
    *linux*)
      ax_random_device='"/dev/random"'
      ;;
    *)
      ax_random_device='"/dev/urandom"'
      ;;
    esac
  elif test x"${ax_have__dev_urandom}" = xyes
  then
    ax_random_device='"/dev/urandom"'
  elif test x"${ax_have__dev_random}" = xyes
  then
    ax_random_device='"/dev/random"'
  else
    AC_CHECK_PROGS([PRNGD],[egd prngd],[
    AC_MSG_ERROR(EGD nor PRNGD is found)
    ],[])
    AC_MSG_ERROR(No random device file, but $PRNGD is found, specify --with-random-device="path" to connect it)
  fi
  AC_DEFINE_UNQUOTED([$1],[${ax_random_device}],
    [Pathname to the random device file, or socket to EGD/PRNG])
  $1=${ax_random_device}
  AC_SUBST([$1])
])
