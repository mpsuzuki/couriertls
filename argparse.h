#ifndef	argparse_h
#define	argparse_h

/*
** Copyright 2000 Double Precision, Inc.
** See COPYING for distribution information.
*/


#include	"config.h"

extern	const char* debug;

struct args {
	const char *name;
	const char **valuep;
	void (*funcp)(const char *);
	} ;

int argparse(int argc, char **, struct args *);

#endif
