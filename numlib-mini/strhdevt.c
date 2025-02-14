/*
** Copyright 1998 - 2003 Double Precision, Inc.
** See COPYING for distribution information.
*/

#include	"numlib.h"
#include	<string.h>


static const char xdigit[]="0123456789ABCDEF";

char *libmail_strh_dev_t(dev_t t, char *arg)
{
char	buf[sizeof(t)*2+1];
char	*p=buf+sizeof(buf)-1;
unsigned i;

	*p=0;
	for (i=0; i<sizeof(t)*2; i++)
	{
		*--p= xdigit[t & 15];
		t=t / 16;
	}
	return (strcpy(arg, p));
}
