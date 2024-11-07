dnl Process this file with autoconf to produce a configure script.
dnl
dnl Copyright 1998 - 2008 Double Precision, Inc.  See COPYING for
dnl distribution information.

AC_PREREQ([2.62])
AC_INIT([couriertls-server],[0.11.20241101],[https://gitlab.com/mpsuzuki/couriertls/-/issues])
AM_INIT_AUTOMAKE([foreign])

# >confdefs.h  # Kill PACKAGE_ macros

AC_CONFIG_SRCDIR(starttls.c)
# AC_CONFIG_AUX_DIR(../..)
LPATH="$PATH:/usr/local/bin"
AC_CONFIG_HEADERS(config.h)
AC_CONFIG_SUBDIRS([liblock-mini numlib-mini soxwrap])

dnl Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_RANLIB
# LT_INIT

SPATH="$LPATH:/usr/kerberos/bin"

AC_PATH_PROG(SED, sed, sed, $SPATH)
if test "$SED" = "sed"
then
	AC_MSG_ERROR(sed not found.)
fi
AC_SUBST(SED)

AC_PATH_PROG(SETENV, env, env, $SPATH)
if test "$SETENV" = "env"
then
	AC_MSG_ERROR(env not found.)
fi
AC_SUBST(SETENV)

PKG_PROG_PKG_CONFIG

if test x$GCC = xyes
then
	CFLAGS="-Wall $CFLAGS"
fi
if test x$GXX = xyes
then
	CXXFLAGS="-Wall $CXXFLAGS"
fi

#CFLAGS="-I$srcdir/.. -I.. -I$srcdir/../.. -I../.. $CFLAGS"
CFLAGS="-I$builddir -I$srcdir $CFLAGS"
#CXXFLAGS="-I$srcdir/.. -I.. -I$srcdir/../.. -I../.. $CXXFLAGS"
CXXFLAGS="-I$builddir -I$srcdir $CXXFLAGS"

AC_PATH_PROG(KRB5CONFIG, krb5-config, krb5-config, $SPATH)

#
#
# We may need libdl for later, not just shared check.
#

saveLIBS="$LIBS"
AC_CHECK_LIB(dl, dlopen, [ LIBDL="-ldl" ])
LIBS="$saveLIBS"

PKG_CHECK_MODULES(LIBIDN, libidn2 >= 2.0.5, [libidn=yes], [libidn=no])
if test "$libidn" != "yes"
then
	AC_MSG_ERROR([libidn not found])
fi

dnl Determine whether transport libraries are created static or shared

AC_SUBST(LIBDL)

LIBS="$saveLIBS"

USENSL=no
saveLIBS="$LIBS"
AC_CHECK_LIB(socket,socket,result=yes,result=no)
if test $result = yes; then
        NETLIBS="-lsocket"
else
        AC_CHECK_LIB(socket,socket,result=yes,result=no,-lnsl)
        if test $result = yes; then
                NETLIBS = "-lsocket -lnsl"
                USENSL=yes
        else
                AC_CHECK_LIB(socket,connect,result=yes,result=no)
                if test $result = yes; then
                        NETLIBS="-lsocket"
                else
                        AC_CHECK_LIB(socket,connect,result=yes,result=no,-lnsl)
                        if test $result = yes; then
                                NETLIBS="-lsocket -lnsl"
                                USENSL=yes
                        fi
                fi
        fi
fi

if test $USENSL != yes; then
	LIBS="$LIBS $NETLIBS"
	AC_TRY_LINK_FUNC(inet_addr, [ : ],
	[
	        AC_CHECK_LIB(nsl,inet_addr,result=yes,result=no)
	        if test $result = yes; then
	                NETLIBS="$NETLIBS -lnsl"
	        fi
	])
fi

AC_SUBST(NETLIBS)

dnl Checks for header files.

AC_HEADER_DIRENT
AC_CHECK_HEADERS(sys/types.h sys/time.h sys/stat.h sys/wait.h sys/select.h unistd.h fcntl.h sys/ioctl.h)
AC_CHECK_HEADERS_ONCE([sys/time.h])
# Obsolete code to be removed.
if test $ac_cv_header_sys_time_h = yes; then
  AC_DEFINE([TIME_WITH_SYS_TIME],[1],[Define to 1 if you can safely include both <sys/time.h>
	     and <time.h>.  This macro is obsolete.])
fi
# End of obsolete code.


dnl Checks for typedefs, structures, and compiler characteristics.

AC_TYPE_PID_T
AC_TYPE_UID_T
AC_SYS_LARGEFILE

AC_CACHE_CHECK([for socklen_t],
	tcpd_cv_hassocklen_t,

AC_COMPILE_IFELSE([
AC_LANG_SOURCE( [
#include <sys/types.h>
#include <sys/socket.h>

socklen_t sl_t;
],[
	accept(0, 0, &sl_t);
])],
	tcpd_cv_hassocklen_t=yes,
	tcpd_cv_hassocklen_t=no)
)

socklen_t="int"

if test $tcpd_cv_hassocklen_t = yes
then
	:
else
	AC_DEFINE_UNQUOTED(socklen_t, int, [ Default definition for socklen_t ])
fi

dnl Checks for library functions.

PKG_CHECK_MODULES(LIBIDN, libidn2 >= 0.0.0, [libidn=yes], [libidn=no])

if test "$libidn" != "yes"
then
	AC_MSG_ERROR([libidn not found])
fi

AC_CHECK_FUNCS(setpgrp setpgid)
AC_CHECK_FUNC(setpgrp,
	[
	AC_FUNC_SETPGRP
	]
)

AC_ARG_WITH(tcpddns, [  --without-tcpddns       Use resolver instead of DNS lookups in couriertcpd ], tcpddns="$withval", tcpddns="Y")

case "$tcpddns" in
n*|N*|0*)
	;;
*)
	AC_DEFINE_UNQUOTED(TCPDUSERFC1035,1,
	[ Whether to use librfc1035.a to resolve via DNS ])
	;;
esac

saveLIBS="$LIBS"
LIBS="$LIBS $NETLIBS"
AC_CHECK_FUNC(socketpair, have_socketpair=yes, have_socketpair=no)

AC_ARG_WITH(spipe,
[  --with-spipe=socketpair Create stream pipes as BSD socketpairs
  --with-spipe=streams    Create stream pipes as SVR3 streams
  --with-spipe=pipe       Create stream pipes as SVR4 streams],
spipe="$withval", spipe="")

AC_CACHE_CHECK([for SVR3 stream pipes],tcpd_cv_svr3,
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <sys/types.h>
#include <sys/stream.h>
#include <stropts.h>
#include <fcntl.h>
]], [[ {
	(void)(sizeof(struct strfdinsert) +
	        sizeof(queue_t) + I_FDINSERT)
}
]])],[tcpd_cv_svr3=yes],[tcpd_cv_svr3=no]))

AC_CACHE_CHECK( [for SVR4 stream pipes],tcpd_cv_svr4,

AC_RUN_IFELSE([AC_LANG_SOURCE([[

changequote(<<,>>)

#include	<stdio.h>
#include	<unistd.h>
#include	<stdlib.h>

int main(int argc, char **argv)
{
int	pipefd[2];
char	c;

	c=0;
	if (pipe(pipefd) == 0 && write(pipefd[0], &c, 1) == 1 &&
		read(pipefd[1], &c, 1) == 1 &&
		write(pipefd[1], &c, 1) == 1 &&
		read(pipefd[0], &c, 1) == 1)
	{
		exit (0);
	}
	exit (1);
	return (1);
}
changequote([,])

]])],[tcpd_cv_svr4=yes],[tcpd_cv_svr4=no],[tcpd_cv_svr4="n/a"])

)

LIBS="$saveLIBS"

if test "$spipe" = ""
then
	if test "$have_socketpair" = "yes"
	then
		spipe="socketpair"
	fi
fi

if test "$spipe" = ""
then
	if test "$tcpd_cv_svr3" = "yes"
	then
		spipe="streams"
	fi
fi

if test "$spipe" = ""
then
	if test "$tcpd_cv_svr4" = "yes"
	then
		spipe="pipe"
	fi
fi

case "$spipe" in
socketpair)
		AC_DEFINE_UNQUOTED(HAVE_SPIPE_SOCKETPAIR, 1,
		[ Whether to use socketpair() to create a bidirectional pipe ])
		;;
streams)
		AC_DEFINE_UNQUOTED(HAVE_SPIPE_SVR3, 1,
		[ Whether to use streams to create a vidirectional pipe ])
		;;
pipe)
		AC_DEFINE_UNQUOTED(HAVE_SPIPE_SVR4, 1,
		[ Whether pipe() is SvR4-style that's a bidirectional pipe ])
		;;
*)
	AC_MSG_ERROR(Cannot determine stream pipe support.  If cross-compiling use --with-spipe=pipe to get SVR4 stream pipes.)
		;;
esac


AC_MSG_CHECKING([for stream pipes])
AC_MSG_RESULT($spipe)

# Checks for liblock
AC_CHECK_HEADER([liblock/config.h],[
  AC_DEFINE([HAVE_LIBLOCK_CONFIG_H],[1],[Defined to 1 if liblock/config.h is available])
])
AC_CHECK_LIB([lock], [ll_lockfd], [
  LIBLOCK_CFLAGS=
  LIBLOCK_LIBS=-llock
], [
  AC_MSG_WARN([use included copy of 'liblock-mini'])
  LIBLOCK_CFLAGS='-I$(top_builddir)/liblock-mini -I$(top_srcdir)/liblock-mini'
  LIBLOCK_LIBS='-L$(top_builddir)/liblock-mini -llock'
  AC_DEFINE([USE_LIBLOCK_MINI],[1],[Define 1 to use included copy of 'liblock-mini'])
])
AM_CONDITIONAL(HAVE_LIBLOCK, [test "x${ac_cv_lib_lock_ll_lockfd}" != xyes])
AC_SUBST([LIBLOCK_CFLAGS])
AC_SUBST([LIBLOCK_LIBS])

# Checks for numlib
AC_CHECK_HEADER([numlib/config.h],[
  AC_DEFINE([HAVE_NUMLIB_CONFIG_H],[1],[Defined to 1 if numlib/config.h is available])
])
AC_CHECK_HEADER([numlib.h],[
  NUMLIB_CPPFLAGS=
],[
  AC_MSG_WARN([use included copy of 'numlib-mini'])
  NUMLIB_CPPFLAGS='-I$(top_builddir)/numlib-mini -I$(top_srcdir)/numlib-mini'
])
AC_SUBST([NUMLIB_CPPFLAGS])

# Checks for soxwrap
AC_CHECK_HEADER([soxwrap.h],[
  SOXWRAP_CPPFLAGS=""
],[
  AC_MSG_WARN([use included copy of 'soxwrap'])
  SOXWRAP_CPPFLAGS='-I$(top_builddir)/soxwrap -I$(top_srcdir)/soxwrap'
])
AC_SUBST([SOXWRAP_CPPFLAGS])


# Checks for libidn2, p11-kit-1
PKG_CHECK_MODULES([IDN2],[libidn2])
# PKG_CHECK_MODULES([P11KIT],[p11-kit-1])

# Checks for random number source
AX_CHECK_RANDOM_SOURCE(RANDOM_DEVICE)

AC_CHECK_HEADER(openssl/ssl.h,have_ssl_h=yes,have_ssl_h=no)
AC_CHECK_LIB(ssl, SSL_load_error_strings, have_ssl=yes, have_ssl=no,
	-lcrypto)
AC_CHECK_LIB(ssl, SSL_library_init, have_ssl=yes)
AC_CHECK_LIB(ssl, OPENSSL_init_ssl, have_ssl=yes)
if test x"${have_ssl}" = xyes
then
  AC_MSG_CHECKING([whether static link flag for openssl works])
  orig_CFLAGS="${CFLAGS}"
  orig_LIBS="${LIBS}"
  CFLAGS="${CFLAGS} "`${PKG_CONFIG} --cflags openssl`
  LIBS="-static ${LIBS} "`${PKG_CONFIG} --libs --static openssl`
  AC_LINK_IFELSE([
                   AC_LANG_PROGRAM([[#include <openssl/ssl.h>]],
                                   [[SSL_CTX_new(TLS_server_method());]])
                 ],[
                   AC_MSG_RESULT(yes)
                   OPENSSL_LIBS_STATIC="-static "`${PKG_CONFIG} --libs --static openssl`
                   IDN2_LIBS_STATIC=`${PKG_CONFIG} --libs --static libidn2`
                 ],[
                   AC_MSG_RESULT(no)
                 ])
  CFLAGS="${orig_CFLAGS}"
  LIBS="${orig_LIBS}"
fi

AM_CONDITIONAL(HAVE_OPENSSL, [test "x${have_ssl}" = xyes])
AC_SUBST([OPENSSL_LIBS_STATIC])

if test "$have_ssl" = "yes"
then
	if test "$have_ssl_h" = "no"
	then
		AC_MSG_WARN(OpenSSL runtime libraries installed but the header files are missing)
		AC_MSG_WARN(disabling OpenSSL support.)
		have_ssl="no"
	fi
fi

KRBFLAGS=""
if test "$have_ssl" = "yes"
then
	LIBCOURIERTLSOPENSSL=libcouriertlsopenssl.la

	AC_CHECK_LIB(ssl, SSL_CTX_set_alpn_protos, [
		  AC_DEFINE_UNQUOTED(HAVE_OPENSSL_ALPN, 1,
					[ Whether OpenSSL supports ALPN ])
		])

	if test "$KRB5CONFIG" != "krb5-config"
	then
		AC_MSG_CHECKING(whether OpenSSL requires Kerberos)
		AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <openssl/ssl.h>
]], [[ ]])],[:],[
			KRBFLAGS=`$KRB5CONFIG --cflags`
			CFLAGS="$CFLAGS $KRBFLAGS"


			AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <openssl/ssl.h>
]], [[ ]])],[ KRBLIBS="`$KRB5CONFIG --libs`" ],[AC_MSG_ERROR(OpenSSL test build failed) ])

])

		if test "$KRBLIBS" = ""
		then
			AC_MSG_RESULT(no)
		else
			AC_MSG_RESULT(yes)
		fi
	fi
	# openssldep="-lssl -lcrypto $KRBLIBS $NETLIBS ../random128/librandom128.la"
	if test "x${OPENSSL_LIBS_STATIC}" != "x"
	then
		openssldep="${OPENSSL_LIBS_STATIC} ${IDN2_LIBS_STATIC} $KRBLIBS $NETLIBS"
	else
		openssldep="-lssl -lcrypto $KRBLIBS $NETLIBS"
	fi
fi

# GnuTLS

have_gnutls=no

AC_MSG_CHECKING([for GnuTLS])

if test "$PKG_CONFIG" != ""
then
	if $PKG_CONFIG --modversion gnutls >/dev/null 2>&1
	then
		save_CPPFLAGS="$CPPFLAGS"
		CPPFLAGS="$CPPFLAGS `$PKG_CONFIG --cflags gnutls`"

		AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <gnutls/gnutls.h>
]], [[
	]])],[ have_gnutls=yes
		],[
			have_gnutls="no: \#include <gnutls/gnutls.h> failed"
		])

		CPPFLAGS="$save_CPPFLAGS"
	else
		have_gnutls="no: pkgconfig --modversion gnutls failed"
	fi
else
	have_gnutls="no: pkg-config not found"
fi
AC_MSG_RESULT($have_gnutls)

# GnuTLS has long dependency, the link flag should be tested before testing static link
if test "$have_gnutls" = "yes"
then
	CFLAGS_orig="${CFLAGS}"
	LIBS_orig="${LIBS}"
	AC_MSG_CHECKING([whether default link flag for gnutls works])
	CFLAGS="${CFLAGS} "`${PKG_CONFIG} --cflags gnutls`
	LIBS="${LIBS} "`${PKG_CONFIG} --libs gnutls`
	AC_LINK_IFELSE([ AC_LANG_PROGRAM(
				[[#include <gnutls/gnutls.h>]],
				[[gnutls_global_init();]]	)
			],[
				AC_MSG_RESULT(yes)
			],[
				AC_MSG_RESULT(no)
				AX_CHECK_PKG_LIBS_NEEDS_RPATH([gnutls],[
					AC_LANG_PROGRAM([[#include <gnutls/gnutls.h>]],
							[[gnutls_global_init();]])
				],[
					AC_MSG_RESULT([yes])
					have_gnutls=yes
				],[
					AC_MSG_RESULT([no])
					have_gnutls=no
				])
			])
	CFLAGS="${CFLAGS_orig}"
	LIBS="${LIBS_orig}"
fi

AM_CONDITIONAL(HAVE_GNUTLS, [test "x${have_gnutls}" = xyes])

if test "$have_gnutls" = "yes"
then
	CFLAGS_orig="${CFLAGS}"
	LIBS_orig="${LIBS}"
	AC_MSG_CHECKING([whether static link flag for gnutls works])
	CFLAGS="${CFLAGS} "`${PKG_CONFIG} --cflags gnutls`
	LIBS="-static ${LIBS} "`${PKG_CONFIG} --libs --static gnutls`
	AC_LINK_IFELSE([ AC_LANG_PROGRAM(
				[[#include <gnutls/gnutls.h>]],
				[[gnutls_global_init();]]	)
			],[
				AC_MSG_RESULT(yes)
				GNUTLS_LIBS_STATIC="-static "`${PKG_CONFIG} --libs --static gnutls`
       			],[
				AC_MSG_RESULT(no)
				AC_MSG_CHECKING([whether static link flag for gnutls lacks -lm])
				# XXX "-lm" is not sufficiently portable, search math library
				LIBS="${LIBS} -lm"
				AC_LINK_IFELSE([
					AC_LANG_PROGRAM(
						[[#include <gnutls/gnutls.h>]],
						[[gnutls_global_init();]]	)
				],[
					AC_MSG_RESULT(yes)
					GNUTLS_LIBS_STATIC="-static "`${PKG_CONFIG} --libs --static gnutls`" -lm"
				],[
					AC_MSG_RESULT(no)
				])
			])
	CFLAGS="${CFLAGS_orig}"
	LIBS="${LIBS_orig}"
	AC_SUBST([GNUTLS_LIBS_STATIC])


	LIBCOURIERTLSGNUTLS="libcouriertlsgnutls.la"
	CPPFLAGS="$CPPFLAGS `$PKG_CONFIG --cflags gnutls`"
	have_gnutls3=no
	PKG_CHECK_EXISTS([gnutls >= 3.0], [have_gnutls3=yes])
	if test "x${GNUTLS_LIBS_STATIC}" != "x"
	then
		gnutlsdep="{$GNUTLS_LIBS_STATIC}"
	else
		gnutlsdep=`$PKG_CONFIG --libs gnutls`
	fi
	if test "x$have_gnutls3" = "xno"
	then
		gnutlsdep="${gnutlsdep} -lgnutls-extra"
	else
		AC_DEFINE([HAVE_GNUTLS3], [1], [Use GnuTLS3])
	fi

	AC_CHECK_LIB(gnutls, gnutls_alpn_set_protocols, [
		  AC_DEFINE_UNQUOTED(HAVE_GNUTLS_ALPN, 1,
					[ Whether GnuTLS supports ALPN ])
		])
fi

AC_CHECK_SIZEOF(gnutls_transport_ptr_t,0, [
AC_INCLUDES_DEFAULT
#include <gnutls/gnutls.h>
])

AC_CHECK_SIZEOF(long,0)

cast_to_ptr_t=""

if test "$gnutls_transport_ptr_t_SIZEOF" = "$long_SIZEOF"
then
	if test "$gnutls_transport_ptr_t_SIZEOF" != 0
	then
		cast_to_ptr_t="(long)"
	fi
fi

AC_DEFINE_UNQUOTED(GNUTLS_CAST_PTR_T, $cast_to_ptr_t,[How to cast a file descriptor to gnutls_transport_ptr_t])

echo "cppflags='$KRBFLAGS'" >couriertls.config

AC_SUBST(openssldep)
AC_SUBST(gnutlsdep)

# Choose GnuTLS or OpenSSL

AC_ARG_WITH(gnutls, [  --with-gnutls     Use GnuTLS even if OpenSSL is available],
		    [

if test "$withval" = "yes"
then
	if test "$have_gnutls" = "yes"
	then
		have_ssl="no"
	else
		AC_MSG_ERROR(Cannot find GnuTLS)
	fi
else
	have_gnutls="no"
fi
],
	[

	if test "$have_ssl" = "yes"
	then
		have_gnutls="no"
	fi
])

if test "$have_gnutls" = "yes"
then
	TLSLIBRARY="$LIBCOURIERTLSGNUTLS"
	STARTTLS=couriertls$EXEEXT
	BUILDLIBCOURIERTLS=libcouriertls.la

	CRYPTLIBS=""

	AC_MSG_CHECKING([for libgcrypt])

	save_LIBS="$LIBS"
	LIBS="$LIBS -lgcrypt"
	AC_LINK_IFELSE([AC_LANG_PROGRAM([[
#include <gcrypt.h>

]], [[
	gcry_cipher_open(NULL, 0, 0, 0);
]])],[
	AC_MSG_RESULT(yes)
	AC_DEFINE_UNQUOTED(HAVE_GCRYPT, 1,
				[ Whether libgcrypt is installed ])
	CRYPTLIBS="$CRYPTLIBS -lgcrypt"
],[
AC_MSG_RESULT(no)
have_gcrypt="no"
])

	if test "$have_gcrypt" = "no"
	then
		AC_MSG_ERROR(gcrypt header file is required for GNUTLS)
	fi
	AC_MSG_CHECKING([for libgpg-error])
	LIBS="$LIBS -lgpg-error"
	AC_LINK_IFELSE([AC_LANG_PROGRAM([[
#include <gcrypt.h>

]], [[
	gpg_err_code_from_errno(0);
]])],[
	AC_MSG_RESULT(yes)
	CRYPTLIBS="$CRYPTLIBS -lgpg-error"
],[
AC_MSG_RESULT(no)
])

	LIBS="$save_LIBS"

	echo "ssllib=gnutls" >>couriertls.config
else
	if test "$have_ssl" = "yes"
	then

		save_LIBS="$LIBS"
		LIBS="-lcrypto $KRBLIBS $LIBS"

		AC_CHECK_FUNCS(PEM_read_bio_Parameters_ex)
		AC_MSG_CHECKING(for OpenSSL 0.9.7)
		AC_LINK_IFELSE([AC_LANG_PROGRAM([[
#include <openssl/evp.h>
#include <openssl/rand.h>
]], [[
EVP_CIPHER_CTX ctx;
char dummy[1];
unsigned char a[1], b[1];

EVP_CIPHER_CTX_init(&ctx);
EVP_EncryptInit_ex(&ctx, EVP_des_cbc(), NULL, a, b);
RAND_pseudo_bytes(dummy, 1);

]])],[
   CRYPTLIBS="-lcrypto $KRBLIBS"
   AC_MSG_RESULT(yes)
   AC_DEFINE_UNQUOTED(HAVE_OPENSSL097, 1,
				       [ Whether OpenSSL 0.9.7 is installed ])
],[
   AC_MSG_RESULT(no)



		AC_MSG_CHECKING(for OpenSSL 1.1.0)
		AC_LINK_IFELSE([AC_LANG_PROGRAM([[
#include <openssl/evp.h>
#include <openssl/rand.h>
]], [[
unsigned char dummy[1];
unsigned char a[1], b[1];

EVP_CIPHER_CTX *ctx=EVP_CIPHER_CTX_new();
EVP_EncryptInit_ex(ctx, EVP_des_cbc(), NULL, a, b);
RAND_bytes(dummy, 1);

]])],[
   CRYPTLIBS="-lcrypto $KRBLIBS"
   AC_MSG_RESULT(yes)
   AC_DEFINE_UNQUOTED(HAVE_OPENSSL110, 1,
				       [ Whether OpenSSL 1.1.0 is installed ])
],[
   AC_MSG_RESULT(no)
])


])
		LIBS="-lssl $LIBS"
		AC_CHECK_FUNCS(TLSv1_1_method TLSv1_2_method X509_VERIFY_PARAM_set1_host)
		LIBS="$save_LIBS"

		AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <openssl/ssl.h>

SSL *p;
]], [[
(void)SSL_get_servername(p, TLSEXT_NAMETYPE_host_name);
]])],[
                AC_DEFINE_UNQUOTED(HAVE_OPENSSL_SNI,1,[ Whether OpenSSL supports SNI ])
		],[])

		TLSLIBRARY="$LIBCOURIERTLSOPENSSL"
		STARTTLS=couriertls$EXEEXT
		BUILDLIBCOURIERTLS=libcouriertls.la
		echo "ssllib=openssl" >>couriertls.config
	fi
fi
echo "couriertls=$STARTTLS" >>couriertls.config
echo "cryptlibs=\"`echo $CRYPTLIBS`\"" >>couriertls.config

## Do not built the other SSL library.  ... Except if I'm the maintainer
#
#if test ! -d "$srcdir/CVS"
#then
#	if test "$have_ssl" = "yes"
#	then
#		LIBCOURIERTLSGNUTLS=""
#		fi
#
#	if test "$have_gnutls" = "yes"
#	then
#		LIBCOURIERTLSOPENSSL=""
#	fi
#fi

AC_SUBST(LIBCOURIERTLSOPENSSL)
AC_SUBST(LIBCOURIERTLSGNUTLS)

AC_SUBST(CRYPTLIBS)
AC_SUBST(STARTTLS)
AC_SUBST(BUILDLIBCOURIERTLS)
AC_SUBST(TLSLIBRARY)

AC_CONFIG_FILES([GNUmakefile])
AC_OUTPUT
