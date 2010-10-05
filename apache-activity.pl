#! /usr/bin/perl

use strict;
use Data::Dumper;
#use warnings;


# check whether any ServerAliases point here
# check for last write to CustomLog or for last entry in central logs
# check for files in DocumentRoot


my (@vhosts, %VirtualHosts, %system);
my $vhostConfig = "/home/avi/bin/test/apache-activity/*";
# Get system properties into $system:
%system = %{&getSystemInfo};

# Get all vhost config into %virtualHosts
&getVhostInfo($vhostConfig);
foreach(@vhosts){
	&parseVhostConfig($_);
}


#my $ips = $system{'ips'};
#my @ips = @$ips;
#foreach(@ips){
#		print $_;
#}


foreach(keys(%VirtualHosts)){
	print "\n$_ ";
	my $CustomLog = $VirtualHosts{$_}{'CustomLog'};
	my $LogFormat = $VirtualHosts{$_}{'LogFormat'};
	my $ConfigFile = $VirtualHosts{$_}{'configFile'};
	my $numAliases = $VirtualHosts{$_}{'NumAliases'};
	my $DocumentRoot = $VirtualHosts{$_}{'DocumentRoot'};
	my @ServerAliases = @{$VirtualHosts{$_}{'ServerAliases'}};

	print "\n\t$ConfigFile";

}
print "\n";




# Given a directory as an argument, checks whether it's got a likely website in it.
# Returns zero if the dir's empty or non-existant, else the number of files in it.
## Doesn't work, since I can't get the DocumentRoot out of the files !?
sub DocumentRootIsEmpty(){
	my $DocumentRoot = shift;

	eval{ 
		opendir(my $dh, $DocumentRoot);
		my @files = grep { !/^\./ && !/^logs*/ } readdir($dh);
		my $filesCount = @files;
		return $filesCount;
	};
	if($@){
		return -1;
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
#				&parseVhostConfig($vhostConfigFile);
				&splitVhostFile($vhostConfigFile);
				
			}
		}
	}else{
#		&parseVhostConfig($_);
		&splitVhostFile($_);
	}
}

# Is passed a file containing one or more vhost configurations, and splits this 
# up into arrays, one array per virtualhost. Pushes them to global @vhosts array.
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
#			print "\t\t".$line."\n";
			push(@vhost, $line);
			if($fileContents[$count] =~ /^\s?\<\/VirtualHost/i){
#				print "$file\n\n";
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

	my $arrayref = shift;
	my @vhostConfig = @$arrayref;

	my ($ServerName, $ServerAlias, $CustomLog, $LogFormat, $DocumentRoot);
	my (@ServerAliases);

	my $filename = $vhostConfig[0];

#	my $vhostConfigLength = @vhostConfig;
#	print "--".$vhostConfigLength." ".$filename."\n";

#	if ($filename =~ /aviswe/){
#		print $filename;
#		my $vhostConfigSize = @vhostConfig;
#		print "aaaaaaa $vhostConfigSize nbbbbbbb\n";
#		foreach(@vhostConfig){
#			print "\"$_\"\n";
#		}
#	}

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



###########
# Returns a reference to what will be the contents of %System, which is a 
# hash of local system properties and (soon) Apache defaults.
sub getSystemInfo() {
	my %hash;

	my $ips = &getLocalIpAddresses();
	$hash{'ips'} = $ips ;

	return \%hash;
}



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
