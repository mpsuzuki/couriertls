# couriertls-server
separated package of "couriertls" program from
https://github.com/svarshavchik/courier-libs/tree/master/tcpd

## Purpose
Today, the vulnerabilities of SSL/TLS libraries or
old algorithm is the most frequent factor that we
have to upgrade the programs connected to the Internet.
To make the partial upgrade of Courier-MTA easier,
I separated "couriertls" in courier-libs/tcpd/ as
a small self-contained package.
Also, to minimize the dependencies, I removed
some features of couriertls.

- connecting to the Internet by itself. this minimized version must be invoked from couriertcpd (or DJB tcpserver?)
- working as a client to connect some SSL/TLS server
- STARTTLS features

suzuki toshiya
