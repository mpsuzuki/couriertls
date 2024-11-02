/*
** Copyright 2000-2018 Double Precision, Inc.
** See COPYING for distribution information.
*/
#include	"config.h"
#include	"argparse.h"
#include	"spipe.h"

#include	"libcouriertls.h"
#include	"tlscache.h"
#include	"rfc1035/rfc1035.h"
#include	"soxwrap/soxwrap.h"
#include	"numlib/numlib.h"

#ifdef  getc
#undef  getc
#endif
#include	<stdio.h>
#include	<string.h>
#include	<stdlib.h>
#include	<ctype.h>
#include	<netdb.h>
#include	<signal.h>
#if HAVE_DIRENT_H
#include <dirent.h>
#define NAMLEN(dirent) strlen((dirent)->d_name)
#else
#define dirent direct
#define NAMLEN(dirent) (dirent)->d_namlen
#if HAVE_SYS_NDIR_H
#include <sys/ndir.h>
#endif
#if HAVE_SYS_DIR_H
#include <sys/dir.h>
#endif
#if HAVE_NDIR_H
#include <ndir.h>
#endif
#endif
#if	HAVE_UNISTD_H
#include	<unistd.h>
#endif
#if	HAVE_FCNTL_H
#include	<fcntl.h>
#endif
#include	<errno.h>
#if	HAVE_SYS_TYPES_H
#include	<sys/types.h>
#endif
#if	HAVE_SYS_STAT_H
#include	<sys/stat.h>
#endif
#include	<sys/socket.h>
#include	<arpa/inet.h>

#include        <time.h>
#if HAVE_SYS_TIME_H
#include        <sys/time.h>
#endif

#include	<locale.h>


/* Command-line options: */

const char *localfd=0;
const char *remotefd=0;
const char *statusfd=0;
const char *tcpd=0;
const char *peer_verify_domain=0;
const char *fdprotocol=0;
static FILE *errfp;
static FILE *statusfp;

const char *printx509=0;

static void ssl_errmsg(const char *errmsg, void *dummy)
{
	const char *loglevel_prefix="";
	const char *tcpremoteip=getenv("TCPREMOTEIP");
	const char *errmsgpfix="";
	const char *errmsgsfix="";

	if (strncmp(errmsg, "DEBUG: ", 7) == 0)
	{
		loglevel_prefix="DEBUG: ";
		errmsg += 7;
	}

	if (tcpremoteip && *tcpremoteip)
	{
		errmsgpfix="ip=[";
		errmsgsfix="], ";
	}
	else
	{
		tcpremoteip="";
	}

	fprintf(errfp, "%s%s%s%s%s\n",
		loglevel_prefix,
		errmsgpfix, tcpremoteip, errmsgsfix,
		errmsg);
	fflush(errfp);
}

static void nonsslerror(const char *pfix)
{
	fprintf(errfp, "%s: %s\n", pfix, strerror(errno));
}

void docopy(ssl_handle ssl, int sslfd, int stdinfd, int stdoutfd)
{
	struct tls_transfer_info transfer_info;

	char from_ssl_buf[BUFSIZ], to_ssl_buf[BUFSIZ];
	char *fromptr;
	int rc;

	fd_set	fdr, fdw;
	int	maxfd=sslfd;

	if (fcntl(stdinfd, F_SETFL, O_NONBLOCK)
	    || fcntl(stdoutfd, F_SETFL, O_NONBLOCK)
	    )
	{
		nonsslerror("fcntl");
		return;
	}

	if (maxfd < stdinfd)	maxfd=stdinfd;
	if (maxfd < stdoutfd)	maxfd=stdoutfd;

	tls_transfer_init(&transfer_info);

	transfer_info.readptr=fromptr=from_ssl_buf;

	for (;;)
	{
		if (transfer_info.readptr == fromptr)
		{
			transfer_info.readptr=fromptr=from_ssl_buf;
			transfer_info.readleft=sizeof(from_ssl_buf);
		}
		else
			transfer_info.readleft=0;

		FD_ZERO(&fdr);
		FD_ZERO(&fdw);

		rc=tls_transfer(&transfer_info, ssl, sslfd, &fdr, &fdw);

		if (rc == 0)
			continue;
		if (rc < 0)
			break;

		if (!tls_inprogress(&transfer_info))
		{
			if (transfer_info.readptr > fromptr)
				FD_SET(stdoutfd, &fdw);

			if (transfer_info.writeleft == 0)
				FD_SET(stdinfd, &fdr);
		}

		if (select(maxfd+1, &fdr, &fdw, 0, 0) <= 0)
		{
			if (errno != EINTR)
			{
				nonsslerror("select");
				break;
			}
			continue;
		}

		if (FD_ISSET(stdoutfd, &fdw) &&
		    transfer_info.readptr > fromptr)
		{
			rc=write(stdoutfd, fromptr,
				 transfer_info.readptr - fromptr);

			if (rc <= 0)
				break;

			fromptr += rc;
		}

		if (FD_ISSET(stdinfd, &fdr) && transfer_info.writeleft == 0)
		{
			rc=read(stdinfd, to_ssl_buf, sizeof(to_ssl_buf));
			if (rc <= 0)
				break;

			transfer_info.writeptr=to_ssl_buf;
			transfer_info.writeleft=rc;
		}
	}

	tls_closing(&transfer_info);

	for (;;)
	{
		FD_ZERO(&fdr);
		FD_ZERO(&fdw);

		if (tls_transfer(&transfer_info, ssl, sslfd, &fdr, &fdw) < 0)
			break;

		if (select(maxfd+1, &fdr, &fdw, 0, 0) <= 0)
		{
			if (errno != EINTR)
			{
				nonsslerror("select");
				break;
			}
			continue;
		}
	}
}

struct dump_capture_subject {
	char line[1024];
	int line_size;

	int set_subject;
	int seen_subject;
	int in_subject;
	FILE *fp;
};

static void dump_to_fp(const char *p, int cnt, void *arg)
{
	struct dump_capture_subject *dcs=(struct dump_capture_subject *)arg;
	char *n, *v;
	char namebuf[64];

	if (cnt < 0)
		cnt=strlen(p);

	if (dcs->fp && fwrite(p, cnt, 1, dcs->fp) != 1)
		; /* NOOP */

	while (cnt)
	{
		if (*p != '\n')
		{
			if (dcs->line_size < sizeof(dcs->line)-1)
				dcs->line[dcs->line_size++]=*p;

			++p;
			--cnt;
			continue;
		}
		dcs->line[dcs->line_size]=0;
		++p;
		--cnt;
		dcs->line_size=0;

		if (strncmp(dcs->line, "Subject:", 8) == 0)
		{
			if (dcs->seen_subject)
				continue;

			dcs->seen_subject=1;
			dcs->in_subject=1;
			continue;
		}

		if (!dcs->in_subject)
			continue;

		if (dcs->line[0] != ' ')
		{
			dcs->in_subject=0;
			continue;
		}

		for (n=dcs->line; *n; n++)
			if (*n != ' ')
				break;

		for (v=n; *v; v++)
		{
			*v=toupper(*v);
			if (*v == '=')
			{
				*v++=0;
				break;
			}
		}

		namebuf[snprintf(namebuf, sizeof(namebuf)-1,
				 "TLS_SUBJECT_%s", n)]=0;

		if (dcs->set_subject)
			setenv(namebuf, v, 1);
	}
}

static int verify_connection(ssl_handle ssl, void *dummy)
{
	FILE	*printx509_fp=NULL;
	int	printx509_fd=0;
	char	*buf;

	struct dump_capture_subject dcs;

	memset(&dcs, 0, sizeof(dcs));

	if (printx509)
	{
		printx509_fd=atoi(printx509);

		printx509_fp=fdopen(printx509_fd, "w");
                if (!printx509_fp)
                        nonsslerror("fdopen");
	}

	dcs.fp=printx509_fp;

	dcs.set_subject=0;

	if (tls_certificate_verified(ssl))
		dcs.set_subject=1;

	tls_dump_connection_info(ssl, 1, dump_to_fp, &dcs);

	if (printx509_fp)
	{
		fclose(printx509_fp);
	}

	if (statusfp)
	{
		fclose(statusfp);
		statusfp=NULL;
		errfp=stderr;
	}

	buf=tls_get_encryption_desc(ssl);

	setenv("TLS_CONNECTED_PROTOCOL",
	       buf ? buf:"(unknown)", 1);

	if (buf)
		free(buf);
	return 1;
}

/* ----------------------------------------------------------------------- */

static void startclient(int argn, int argc, char **argv, int fd,
	int *stdin_fd, int *stdout_fd)
{
pid_t	p;
int	streampipe[2];

	if (localfd)
	{
		*stdin_fd= *stdout_fd= atoi(localfd);
		return;
	}

	if (argn >= argc)	return;		/* Interactive */

	if (libmail_streampipe(streampipe))
	{
		nonsslerror("libmail_streampipe");
		exit(1);
	}
	if ((p=fork()) == -1)
	{
		nonsslerror("fork");
		close(streampipe[0]);
		close(streampipe[1]);
		exit(1);
	}
	if (p == 0)
	{
	char **argvec;
	int n;

		close(fd);	/* Child process doesn't need it */
		dup2(streampipe[1], 0);
		dup2(streampipe[1], 1);
		close(streampipe[0]);
		close(streampipe[1]);

		argvec=malloc(sizeof(char *)*(argc-argn+1));
		if (!argvec)
		{
			nonsslerror("malloc");
			exit(1);
		}
		for (n=0; n<argc-argn; n++)
			argvec[n]=argv[argn+n];
		argvec[n]=0;
		execvp(argvec[0], argvec);
		nonsslerror(argvec[0]);
		exit(1);
	}
	close(streampipe[1]);

	*stdin_fd= *stdout_fd= streampipe[0];
}

static int connect_completed(ssl_handle ssl, int fd)
{
	struct tls_transfer_info transfer_info;
	tls_transfer_init(&transfer_info);

	while (tls_connecting(ssl))
	{
		fd_set	fdr, fdw;

		FD_ZERO(&fdr);
		FD_ZERO(&fdw);
		if (tls_transfer(&transfer_info, ssl,
				 fd, &fdr, &fdw) < 0)
			return (0);

		if (!tls_connecting(ssl))
			break;

		if (select(fd+1, &fdr, &fdw, 0, 0) <= 0)
		{
			if (errno != EINTR)
			{
				nonsslerror("select");
				return (0);
			}
		}
	}
	return (1);
}

static void child_handler()
{
	alarm(10);
}

static void trapexit()
{
	struct sigaction sa;

	memset(&sa, 0, sizeof(sa));

	sa.sa_handler=child_handler;
	sigaction(SIGCHLD, &sa, NULL);
}

static int dossl(int fd, int argn, int argc, char **argv)
{
	ssl_context ctx;
	ssl_handle ssl;

	int	stdin_fd, stdout_fd;
	struct tls_info info= *tls_get_default_info();

	info.peer_verify_domain=peer_verify_domain;
	info.tls_err_msg=ssl_errmsg;
	info.connect_callback= &verify_connection;
	info.app_data=NULL;

	stdin_fd=0;
	stdout_fd=1;

	ctx=tls_create(1, &info);
	if (ctx == 0)	return (1);

	ssl=tls_connect(ctx, fd);

	if (!ssl)
	{
		close(fd);
		tls_destroy(ctx);
		return (1);
	}

	if (!connect_completed(ssl, fd))
	{
		tls_disconnect(ssl, fd);
		close(fd);
		tls_destroy(ctx);
		return 1;
	}

	startclient(argn, argc, argv, fd, &stdin_fd, &stdout_fd);
	trapexit();

	docopy(ssl, fd, stdin_fd, stdout_fd);

	tls_disconnect(ssl, fd);
	close(fd);
	tls_destroy(ctx);
	return (0);
}

int main(int argc, char **argv)
{
int	argn;
int	fd;
static struct args arginfo[] = {
	{ "localfd", &localfd},
	{ "printx509", &printx509},
	{ "remotefd", &remotefd},
	{ "tcpd", &tcpd},
	{ "verify", &peer_verify_domain},
	{ "statusfd", &statusfd},
	{0}};
void (*protocol_func)(int)=0;

	setlocale(LC_ALL, "");
	errfp=stderr;

	argn=argparse(argc, argv, arginfo);

	if (statusfd)
		statusfp=fdopen(atoi(statusfd), "w");

	if (statusfp)
		errfp=statusfp;

	if (tcpd)
	{
		dup2(2, 1);
		fd=0;
	}
	else if (remotefd)
		fd=atoi(remotefd);
	else
	{
		fprintf(errfp, "%s: specify remote location.\n",
			argv[0]);
		return (1);
	}

	if (fd < 0)	return (1);
	if (protocol_func)
		(*protocol_func)(fd);

	return (dossl(fd, argn, argc, argv));
}
