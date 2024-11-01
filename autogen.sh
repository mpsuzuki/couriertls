#!/bin/sh
aclocal
autoheader
automake -a
autoconf

for subdir in numlib liblock-mini soxwrap
do
  if test -d "${subdir}" -a -r "${subdir}"/configure.ac
  then
    (cd "${subdir}" && ../autogen.sh)
  fi
done
