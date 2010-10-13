#! /usr/bin/perl

use strict;
use Data::Dumper;
use Socket;


my (@vhosts, %VirtualHosts, %system);
my $vhostConfig = "/home/avi/bin/test/apache-activity/*";
my @localIPAddresses = &getLocalIpAddresses();

# Get all vhost config into %virtualHosts
&getVhostInfo($vhostConfig);
foreach(@vhosts){
	&parseVhostConfig($_);
}


print "\n||======================================================================\n";

foreach(keys(%VirtualHosts)){
	my $ServerName = $_;
	if ($ServerName !~ /\//){
		my $CustomLog = $VirtualHosts{$_}{'CustomLog'};
		my $LogFormat = $VirtualHosts{$_}{'LogFormat'};
		my $ConfigFile = $VirtualHosts{$_}{'configFile'};
		my $numAliases = $VirtualHosts{$_}{'NumAliases'};
		my $DocumentRoot = $VirtualHosts{$_}{'DocumentRoot'};
		my @ServerAliases = @{$VirtualHosts{$_}{'ServerAliases'}};
	
#		print "\n> - - - - - - - - - - <\n";
		print "|| ServerName: $ServerName";
		print "\n|| Config file: $ConfigFile";
		print "\n|| DocumentRoot: $DocumentRoot";
		print "\n|| Files in DocumentRoot: ".&filesInDocumentRoot($DocumentRoot);
		print "\n|| Log File: $CustomLog ($LogFormat)";
		print "\n|| Last mention in logs:".&lastMentionInLogs($ServerName);
		print "\n|| Domain name points here? ".&domainNamePointsHere($ServerName);
		print "\n||======================================================================\n";
	}
}
print "\n";


# # #  Here be subroutines # # #

sub domainNamePointsHere(){
	my $ServerName = shift;
	## seriously, there's a better way to do this, though this one's surprisingly 
	## easy to read:
	foreach ( @{ $VirtualHosts{$ServerName}{'ServerAliases'} }){
		my $domainName = $_;
		my $packed_ip = gethostbyname($domainName);
		my $ip_address = inet_ntoa($packed_ip);
		if (grep(/^$ip_address$/, @localIPAddresses)){
		return "1";
		}
	}
	return "no";
}


# Returns last write to logfiles in epoch time. Zero if non-determinable
sub lastMentionInLogs(){
	my $ServerName = shift;
	my $logFile = $VirtualHosts{$ServerName}{'CustomLog'} ;
	my $lastlog;
	if ( -e $logFile ){
		$lastlog = (stat $logFile)[9];
	}else{
		$lastlog = 0;
	}

	return $lastlog;
}


# Given a directory as an argument, checks whether it's got a likely website in it.
# Returns zero if the dir's empty or non-existant, else the number of files in it.
# Returns:
#  filecount if directory populated
#  -1 if errors encountered reading directory
#  -2 if the directory doesn't exist
#
## Doesn't work, since I can't get the DocumentRoot out of the files !?
sub filesInDocumentRoot(){
	my $DocumentRoot = shift;

	if (-e $DocumentRoot){
		eval{ 
			opendir(my $dh, $DocumentRoot);
			my @files = grep { !/^\./ && !/^logs*/ } readdir($dh);
			my $filesCount = @files;
			return $filesCount;
		};
		if($@){
			return -1;
		}else{
			return 1;
		}
	}else{
		return -2;
	}
}


# Accepts definition of vhost config path as an argument. Paths ending
# with an asterisk are taken as a directory, else a single file. Calls
# &parseVhostConfig() on either the file it's passed, or every file in
# the directory it's passed.
sub getVhostInfo(){
	$vhostConfig = shift;
	if($vhostConfig =~ /(.+)\/\*$/){
		my $vhostConfigDir = $1;
		opendir(my $dh, $vhostConfigDir);
		my @vhostConfigFiles = readdir($dh);
		foreach(@vhostConfigFiles){
			if (!/^\./){
				my $vhostConfigFile = $vhostConfigDir."/".$_;
				&splitVhostFile($vhostConfigFile);
				
			}
		}
	}else{
		&splitVhostFile($_);
	}
}

# Is passed the path to a file containing one or more vhost configurations, and 
# splits this up into arrays, one array per virtualhost. Pushes them to global 
# @vhosts array.
sub splitVhostFile(){
	my $file = shift;
	open(my $f, "<", $file);
	my @fileContents = <$f>;
	close $file;

	my $fileLines = @fileContents;
	my $count = 0;
	my @vhost;
	push(@vhost, $file);
	for($count = 0; $count <= $fileLines; $count++){
		if( ($fileContents[$count] !~ /^\s?\#/) && ($fileContents[$count] !~ /^$/) ) {
			my $line = $fileContents[$count];
			chomp $line;
			push(@vhost, $line);
			if($fileContents[$count] =~ /^\s?\<\/VirtualHost/i){
				my $vhostConf = [@vhost];
				push(@vhosts, $vhostConf);
				my $lines = @vhost;
				undef(@vhost); 
				push(@vhost, $file);
			}
		}
	}
}

# Populates %VirtualHosts with virtualhost data.

# Iterates through the array it is passed as its only argument, normally
# the one created by &splitVhostsFile; is an array of arrays. Each 
# component array contains a virtualhost configuration block, one line
# per element
#
# %VirtualHosts{$ServerName} = {
#	CustomLog	=>	where the log file is
#	ServerAliases	=>	array of ServerName and ServerAlias values
#	NumAliases	=>	count of the above
#	configFile	=>	which file was parsed
# }
sub parseVhostConfig(){
	## This is incomplete. Changes to make:
	##   not loop through the array twice
	##   recognise failure

	my @vhostConfig;

	my $arrayref = shift;
	if (defined($arrayref)){
		@vhostConfig = @$arrayref;
	}else{
		print STERR "WARN: parseVhostConfig() called with no argument";
		return;
	}

	my ($ServerName, $ServerAlias, $CustomLog, $LogFormat, $DocumentRoot);
	my (@ServerAliases);

	my $filename = $vhostConfig[0];

	foreach(@vhostConfig){
		if (/^\s*DocumentRoot\s+/){
			$DocumentRoot = $_;
		}
		if (/^\s*ServerName\s+([\w\.]+)/){
			$ServerName = $1;
			chomp $ServerName;
			push (@ServerAliases, $ServerName);
			last;
		}
		if (/^\s*ServerAlias\s+(.+)\s*/){
			$ServerAlias = $1;
			my @AliasArray = split(/\s/, $ServerAlias);
			push(@ServerAliases, @AliasArray)
		}
		if (/^\s*CustomLog\s+(.+)\s*/){
			($CustomLog,$LogFormat) = split(/\s/,$1);
		}
	}
	if ( ($filename =~ /000-default/) || ($filename =~ /default-ssl/) ){
		$ServerName = $filename;
	}


	if( (exists $VirtualHosts{$ServerName}) && ($filename !~ /000-default/) && ($filename !~ /default-ssl/) ){
		warn "WARN: found two Vhosts claiming to configure $ServerName. The last one wins (in $filename)\n";
	}

	my $numAliases = @ServerAliases;
	$VirtualHosts{$ServerName} = {
		CustomLog	=>	$CustomLog,
		LogFormat	=>	$LogFormat,
		ServerAliases	=>	\@ServerAliases,
		NumAliases	=>	$numAliases,
		configFile	=>	$filename,
		DocumentRoot	=>	$DocumentRoot
	}
}



# # # # # # # # 

# These are the subs that getSystemInfo() calls to get its information: 


# Returns a ref to an array that contains all the IP addresses on 
# this system. To be used when we check whether any of the 
# ServerAliases point at this server
sub getLocalIpAddresses(){
	my @ips;
	my @iplist = `ifconfig -a`;
	foreach (@iplist){
		if (/addr:(\d{0,3}\.\d{0,3}\.\d{0,3}\.\d{0,3})\s/){
			if ($1 !~ /^127/){
				my $ip = $1;
				push (@ips, $ip);
			}
		}
	}
	return \@ips;
}

# Returns Apache's central config for some values; defaults for 
# those parameters not in the vhost config
## needs fixing, currently I'll just hardcode it :)
sub getApacheDetails(){
	my $configfile = "/etc/apache2/apache2.conf";
	my $logfile;	
	eval{
		open(my $f, "<", $configfile);
		my $logfile;
		while(<$f>){
			if (/^CustomLog\s+(\w\/)+/i){
				$logfile=$1;
				last;
			}
		}
	};
	if ($@){
		warn "WARN: Error reading $configfile\n";
	}
	if ($logfile =~ /^$/){
		warn "WARN: Error parsing $configfile; guessing logfile is /var/log/apache2/access.log*\n";
		$logfile="/var/log/apache2/access.log";
	}
}

exit 0;
