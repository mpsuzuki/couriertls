#!/bin/sh
aclocal -I .
autoheader
automake -a
autoconf

for subdir in numlib-mini liblock-mini soxwrap
do
  if test -d "${subdir}" -a -r "${subdir}"/configure.ac
  then
    (cd "${subdir}" && ../autogen.sh)
  fi
done
