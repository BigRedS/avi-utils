avi-utils
=========

This is a collection of scripts I've written that I find useful. I make no claims as to their worthiness for anything
and gladly invite comments and criticism on any and all of them.

All the scripts expect argument(s); run them with none to get usage information, or read this document. 

I generally try not to deviate from perl core, but some of them need really common unixy utilities (top, grep etc),
which are mentioned in comments at the top of each script. Only apachewalk requires perl 5.10 but, seriously, it's 
2010 and even Debian Stable's got it. Which reminds me, these all assume a debianish system. I don't actually know
how others differ from this (except that non-linuxes will need to change the iptables command in allowhost), but it
shouldn't be too difficult.

adissite
--------

       adissite [DocumentRoot] [file]

       Identifies VirtualHosts in the file specified by their
       DocumentRoot definition. Based on a string comparison. 
       Do not include the 'DocumentRoot' part.



Parses an apache 1.x config file looking for the virtualhost defined by the supplied DocumentRoot, then offers to comment
it out for you. Supposed to be a clone of a2dissite for apache 1.x all-config-in-one-file style configuration, but I 
can't help but make these things prompt before writing files.


allowhost
---------

	allowhost <IP address>

	Removes IP address from DenyHosts' files, and restarts
	DenyHosts. Prompts to check with iptables if the IP
	address is not blocked by DenyHosts.



Checks denyhosts' files for evidence of supplied IP address being blocked, and removes them. If it doesn't find any it 
offers to search IPTables for it, too (for fail2ban etc.). Goes through all the daft files in /var/lib/denyhosts and
restarts denyhosts at the end of it all; also copes with the same IP address appearing multiple times in the same file.


apachewalk
----------

         apachewalk <FILE> [OUTPUT]

         Reads Apache configuration file at FILE, following any
         Include directives and outputs the complete configuration
         according to OUTPUT. 

         FILE should be Apache's core configuration file. Often
         /etc/apache/httpd.conf or /etc/apache2/apache2.conf

         OUTPUT dictates the output format:

         file	print every filename included in the config
         line	print every line of configuration
         both	for each line of configuration, print the file it
                was found in and the line found. Handy for grepping
                for "where did I configure that?" type questions.


The script starts at a given apache config file, and prints out every line of config. It follows all Includes, so does actually 
print out the whole config. 

By default, it prefixes each line of config with the name of the file it was found in, which is handy for grepping in 
"where the hell is that Alias configured?" moments. As it comes across an include, it parses the included file (or the 
files in the included directory) before carrying on with that file. I don't know if this is the same order as Apache 
parses it, but it makes little difference since different scopes have different precedence. It is handy that it does 
this when you make use of the fact that the regex by which it determines an 'Include' directive is configured at the 
top of the file, you can alter this to use it on PHP scripts or anything else with a standard 'include' style directive 
or command.

One day, adissite will accept input from it :)


revup
-----

        revup <DOMAIN-NAME>
        
        Performs a DNS lookup for the domain name, then
        a reverse lookup for the resulting IP address. 
        Basically returns the canonical domain name for
        the host at some given domain name.


Given a domain name, does a reverse lookup on the first of its A records. Basically, attempts to find the canonical
domain name of the server at some non-canonical domain name.

qmail-activity
--------------

Has no usage, which is incredibly of slack for me. This needs work but I never use it. It will, one day, be more 
universal as regards what it looks for activity in.

It goes through the contents of qmail's rcpthosts file, and checks each address against the maillogs, to find when that 
domain last saw activity. By default, it looks for three months but doesn't notice if the logs aren't that old.



