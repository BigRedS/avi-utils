avi-utils
=========

This is a collection of scripts I've written that I find useful. I make no claims as to their worthiness for anything
and gladly invite comments and criticism on any and all of them.

* Files with names ending in '.pl' don't work. *


All the scripts expect argument(s); run them with none to get usage information, or read this document. 

I generally try to not deviate from perl core, but some of them need really common unixy utilities (top, grep etc),
which are mentioned in comments at the top of each script. Only apachewalk requires perl 5.10 but, seriously, it's 
2010 and even Debian Stable's got it. Which reminds me, these all assume a debianish system. 

adissite
--------

a2dissite for apache1 style config files. Given a path and an 
httpd.conf it'll comment out the first not-already-commented-out 
vhost in the file with that path as its document root

allowhost
---------

Removes IP address from DenyHosts' files, and restarts
DenyHosts.

apachewalk
----------

Reads an Apache configuration file and, following any
Include directives, outputs the complete configuration
to stdout.

cpmod
-----

Handy script for copying a set of permissions from one hierarchy
to another. Good for clearing up post accidental recursive chmods.

dudt
----

Runs du against a directory, sleeps, then runs it again and tells
you what's changed, by how much, and how fast.

dumpsplitter
------------

Splits big MySQL dumps into small per-table ones.

mxhere
------

Checks whether anyone's likely to try to deliver mail for a particular
domain to any of the IP addresses configured on the host it's run on.

revup
-----

Returns the canonical domain name for a host defined by a non-
canonical domain name.

subdomains
----------

Checks for the existence of DNS records for common subdomains for when 
you want an axfr but can't have one. Crude.

teetime
-------

Sort-of a buffered tail. I've no idea why I called it 'teetime'. Listens on
stdout and stores a buffer of the last several lines, which it will print 
to stdout on command. Can do time- and number-of-lines based buffer sizes

whos
----

Abridged whois output. 
