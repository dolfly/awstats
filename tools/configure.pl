#!/usr/bin/perl
#-------------------------------------------------------
# This script configures AWStats on a Windows OS so AWStats
# is immediately working:
# - Get Apache config file from registry (ask if not found)
# - Add AWStats directives
# - Change common to combined (ask to confirm)
# See COPYING.TXT file about AWStats GNU General Public License.
#-------------------------------------------------------
# $Revision: 1.7 $ - $Author: eldy $ - $Date: 2003-11-08 22:45:36 $
use strict;
use Win32::TieRegistry;


#-------------------------------------------------------
# Defines
#-------------------------------------------------------
use vars qw/ $REVISION $VERSION /;
$REVISION='$Revision: 1.7 $'; $REVISION =~ /\s(.*)\s/; $REVISION=$1;
$VERSION="1.0 (build $REVISION)";

use vars qw/
$DIR $PROG $Extension $Debug
/;

use vars qw/
@WEBCONF
/;
# Possible dirs for Apache conf files
@WEBCONF=(
'C:/Program Files/Apache Group/Apache2/conf/httpd.conf',
'C:/Program Files/Apache Group/Apache/conf/httpd.conf',
'/etc/httpd/httpd.conf',
'/usr/local/apache/conf/httpd.conf',
'/usr/local/apache2/conf/httpd.conf'
);

use vars qw/
$WebServerChanged $UseAlias 
%LogFormat %ConfToChange
/;
$WebServerChanged=0;
$UseAlias=0;
%LogFormat=();
%ConfToChange=();



#-------------------------------------------------------
# Functions
#-------------------------------------------------------

#-------------------------------------------------------
# error
#-------------------------------------------------------
sub error {
	print "Error: $_[0].\n";
    exit 1;
}

#-------------------------------------------------------
# debug
#-------------------------------------------------------
sub debug {
	my $level = $_[1] || 1;
	if ($Debug >= $level) { 
		my $debugstring = $_[0];
		if ($ENV{"GATEWAY_INTERFACE"}) { $debugstring =~ s/^ /&nbsp&nbsp /; $debugstring .= "<br>"; }
		print "DEBUG $level - ".time." : $debugstring\n";
		}
	0;
}

#-------------------------------------------------------
# update_httpd_config
# Replace common to combined in Apache config file
#-------------------------------------------------------
sub update_httpd_config
{
	my $file=shift;
	if (! $file) { error("Call to update_httpd_config with wrong parameter"); }
	
	open(FILE, $file) || error("Failed to open $file for update");
	open(FILETMP, ">$file.tmp") || error("Failed to open $file.tmp for writing");
	
	# $%conf contains param and values
	my %confchanged=();
	my $conflinenb = 0;
	
	# First, change values that are already present in old config file
	while(<FILE>) {
		my $savline=$_;
	
		chomp $_; s/\r//;
		$conflinenb++;
	
		# Remove comments not at beginning of line
		$_ =~ s/\s#.*$//;
	
		# Change line
		if ($_ =~ /^CustomLog\s(.*)\scommon$/i)	{ $savline="CustomLog $1 combined"; }
		
		# Write line
		print FILETMP "$savline";	
	}
	
	close(FILE);
	close(FILETMP);
	
	# Move file to file.sav
	if (rename("$file","$file.old")==0) {
		error("Failed to make backup of current config file to $file.old");
	}
	
	# Move tmp file into config file
	if (rename("$file.tmp","$file")==0) {
		error("Failed to move tmp config file $file.tmp to $file");
	}
	
	return 0;
}

#-------------------------------------------------------
# update_awstats_config
# Update an awstats model [to another one]
#-------------------------------------------------------
sub update_awstats_config
{
my $file=shift;
my $fileto=shift||"$file.tmp";

if (! $file) { error("Call to update_awstats_config with wrong parameter"); }
if ($file =~ /Developpements[\\\/]awstats/i) { return; }	# To avoid script working in my dev area

open(FILE, $file) || error("Failed to open $file for update");
open(FILETMP, ">$fileto") || error("Failed to open $fileto for writing");

# $%conf contains param and values
my %confchanged=();
my $conflinenb = 0;

# First, change values that are already present in old config file
while(<FILE>) {
	my $savline=$_;

	chomp $_; s/\r//;
	$conflinenb++;

	# Remove comments not at beginning of line
	$_ =~ s/\s#.*$//;

	# Extract param and value
	my ($param,$value)=split(/=/,$_,2);
	$param =~ s/^\s+//; $param =~ s/\s+$//;
	$value =~ s/#.*$//; 
	$value =~ s/^[\s\'\"]+//; $value =~ s/[\s\'\"]+$//;

	if ($param) {
		# cleanparam is param without begining #
		my $cleanparam=$param; my $wascleaned=0;
		if ($cleanparam =~ s/^#//) { $wascleaned=1; }
		if (defined($ConfToChange{"$cleanparam"}) && $ConfToChange{"$cleanparam"}) { $savline = ($wascleaned?"#":"")."$cleanparam=\"".$ConfToChange{"$cleanparam"}."\"\n"; }
	}
	# Write line
	print FILETMP "$savline";	
}

close(FILE);
close(FILETMP);

if ($fileto eq "$file.tmp") {
	# Move file to file.sav
	if (rename("$file","$file.old")==0) {
		error("Failed to make backup of current config file to $file.old");
	}
	
	# Move tmp file into config file
	if (rename("$fileto","$file")==0) {
		error("Failed to move tmp config file $fileto to $file");
	}
	# Remove .old file
	unlink "$file.old";
}

return 0;
}



#-------------------------------------------------------
# MAIN
#-------------------------------------------------------
($DIR=$0) =~ s/([^\/\\]*)$//; ($PROG=$1) =~ s/\.([^\.]*)$//; $Extension=$1;

my $QueryString=""; for (0..@ARGV-1) { $QueryString .= "$ARGV[$_] "; }
if ($QueryString =~ /debug=/i) { $Debug=$QueryString; $Debug =~ s/.*debug=//; $Debug =~ s/&.*//; $Debug =~ s/ .*//; }

my $helpfound=0;
my $AWSTATSPATH;
my $OS='';
my $CR='';
for (0..@ARGV-1) {
	if ($ARGV[$_] =~ /^-*h/i)   					{ $helpfound=1; last; }
	if ($ARGV[$_] =~ /^-*awstatspath=([^\s\"]+)/i)  { $AWSTATSPATH==$1; last; }
}
if (! $AWSTATSPATH) {
	$AWSTATSPATH="$DIR";
	$AWSTATSPATH=~s/tools[\\\/]?$//;
	$AWSTATSPATH=~s/[\\\/]$//;
}

# Show usage help
if ($helpfound) {
	print "----- AWStats $PROG $VERSION (c) Laurent Destailleur -----\n";
	print "$PROG is a tool to setup AWStats. It works with Apache only.\n";
	print "- Get Apache config file from registry (ask if not found)\n";
	print " - Add AWStats directives\n";
	print " - Change common to combined (ask to confirm)\n";
	print "\n";
	print "Usage:  $PROG.$Extension\n";
	print "\n";
	exit 0;
}

# Get current time
my $nowtime=time;
my ($nowsec,$nowmin,$nowhour,$nowday,$nowmonth,$nowyear) = localtime($nowtime);
if ($nowyear < 100) { $nowyear+=2000; } else { $nowyear+=1900; }
my $nowsmallyear=$nowyear;$nowsmallyear =~ s/^..//;
if (++$nowmonth < 10) { $nowmonth = "0$nowmonth"; }
if ($nowday < 10) { $nowday = "0$nowday"; }
if ($nowhour < 10) { $nowhour = "0$nowhour"; }
if ($nowmin < 10) { $nowmin = "0$nowmin"; }
if ($nowsec < 10) { $nowsec = "0$nowsec"; }

print "\n";
print "----- AWStats $PROG $VERSION (c) Laurent Destailleur -----\n";
print "This tool will help you to configure AWStats to analyze statistics for\n";
print "one main web server. If you need to analyze several virtual servers,\n";
print "load balanced servers, downloaded log files or mail or ftp log files,\n";
print "you will have to complete the setup manually according to your needs.\n";
print "Read the AWStats documentation (docs/index.html).\n";
print "\n";

# Detect web server path
# ----------------------
if (-d "/etc" && -d "/home") { $OS='linux'; $CR=''; }
else { $OS='windows'; $CR="\r"; }
#print "Running OS detected: $OS (Perl $^[)\n";
print "- Running OS detected: $OS\n";

# Detect web server path
# ----------------------
print "- Check for web server install...\n";
my %ApachePath=();		# All Apache path found
my %ApacheConfPath=();	# All Apache config found
my $tips;
if ($OS eq 'linux') {
	my $found=0;
	foreach my $conf (@WEBCONF) {
		if (-s "$conf") {
			print "  Found Web server Apache config file '$conf'\n";
			$ApacheConfPath{"$conf"}=++$found;
		}
	}
}
if ($OS eq 'windows') {
	$Registry->Delimiter("/");
	if ($tips=$Registry->{"LMachine/Software/Apache Group/Apache/"}) {
		# If Apache registry call successfull
		my $found=0;
		foreach( sort keys %$tips  ) {
			my $path=$Registry->{"LMachine/Software/Apache Group/Apache/$_/ServerRoot"};
			$path=~s/[\\\/]$//;
			if (-d "$path" && -s "$path/conf/httpd.conf") {
				print "  Found a Web server Apache install in '$path'\n";
				$ApachePath{"$path"}=++$found;
				$ApacheConfPath{"$path/conf/httpd.conf"}=++$found;
			}
		}
	}
}

if (! scalar keys %ApacheConfPath) {
	error("Your web server config file(s) could not be found.\nIf you are not using Apache web server, you must setup AWStats manually.\nSee AWStats setup documentation (file docs/index.html)");
	exit 1;
}

# Open Apache config file
# -----------------------
foreach my $key (keys %ApacheConfPath) {
	print "- Check and complete web server config file '$key'...\n";
	# Read config file to search for awstats directives
	READ:
	$LogFormat{$key}=4;
	open(CONF,"<$key") || error("Failed to open config file '$key' for reading");
	binmode CONF;
	my $awstatsjsfound=0;
	my $awstatsclassesfound=0;
	my $awstatscssfound=0;
	my $awstatsiconsfound=0;
	my $awstatscgifound=0;
	while(<CONF>) {
		if ($_ =~ /^CustomLog\s(.*)\scommon$/i)	{
			print "Warning: You Apache config file contains directives to write 'common' log files\n";
			print "This means that some features can't work (os, browsers and keywords detection).\n";
			print "Do you want me to setup Apache to write 'combined' log files [y/N] ?\n";
			my $bidon='';
			while ($bidon !~ /^[yN]$/) { read STDIN, $bidon, 1; }
			if ($bidon eq 'y') {
				close CONF;				
				update_httpd_config("key");
				goto READ;
			}
		}
		if ($_ =~ /^CustomLog\s(.*)\scombined$/i)	{ $LogFormat{$key}=1; }
		if ($_ =~ /Alias \/awstatsjs/) 			{ $awstatsjsfound=1; }
		if ($_ =~ /Alias \/awstatsclasses/) 	{ $awstatsclassesfound=1; }
		if ($_ =~ /Alias \/awstatscss/) 		{ $awstatscssfound=1; }
		if ($_ =~ /Alias \/awstatsicons/) 		{ $awstatsiconsfound=1; }
		if ($_ =~ /ScriptAlias \/awstats\//)	{ $awstatscgifound=1; }
	}	
	close CONF;

	if ($awstatsjsfound && $awstatsclassesfound && $awstatscssfound && $awstatsiconsfound && $awstatscgifound) {
		$UseAlias=1;
		print "  Config file already complete.\n";
		next;
	}
	
	# Add awstats directives
	open(CONF,">>$key") || error("Failed to open config file '$key' for adding AWStats directives");
		binmode CONF;
		print CONF "$CR\n";
		print CONF "#$CR\n";
		print CONF "# Directives to allow use of AWStats as a CGI$CR\n";
		print CONF "#$CR\n";
		if (! $awstatsjsfound) {
			print " Add 'Alias \/awstatsjs \"$AWSTATSPATH/wwwroot/js/\"' to config file\n";
			print CONF "Alias \/awstatsjs \"$AWSTATSPATH/wwwroot/js/$CR\n";
		}
		if (! $awstatsclassesfound) {
			print " Add 'Alias \/awstatsclasses \"$AWSTATSPATH/wwwroot/classes/\"' to config file\n";
			print CONF "Alias \/awstatsclasses \"$AWSTATSPATH/wwwroot/classes/$CR\n";
		}
		if (! $awstatscssfound) {
			print " Add 'Alias \/awstatscss \"$AWSTATSPATH/wwwroot/css/\"' to config file\n";
			print CONF "Alias \/awstatscss \"$AWSTATSPATH/wwwroot/css/$CR\n";
		}
		if (! $awstatsiconsfound) {
			print " Add 'Alias \/awstatsicons \"$AWSTATSPATH/wwwroot/icon/\"' to config file\n";
			print CONF "Alias \/awstatsicons \"$AWSTATSPATH/wwwroot/icon/$CR\n";
		}
		if (! $awstatscgifound) {
			print " Add 'ScriptAlias \/awstats\/ \"$AWSTATSPATH/wwwroot/cgi-bin/\"' to config file\n";
			print CONF "ScriptAlias \/awstats\/ \"$AWSTATSPATH/wwwroot/cgi-bin/$CR\n";
		}
	close CONF;
	$UseAlias=1;
	$WebServerChanged=1;
}

# Define config file path
# -----------------------
my $configfile='';
my $modelfile='';
if ($OS eq 'linux') 	{ $modelfile='/etc/awstats/awstats.model.conf'; $configfile='/etc/awstats/awstats.mysite.conf'; }
if ($OS eq 'windows') 	{ $modelfile="$AWSTATSPATH\\wwwroot\\cgi-bin\\awstats.model.conf"; $configfile="$AWSTATSPATH\\wwwroot\\cgi-bin\\awstats.mysite.conf"; }

# Update model config file
# ------------------------
print "- Update model config file...\n";
%ConfToChange=();
if ($OS eq 'linux') { $ConfToChange{'DirData'}='/var/lib/awstats'; }
if ($OS eq 'windows') { $ConfToChange{'DirData'}='.'; }
if ($UseAlias) {
	$ConfToChange{'DirCgi'}='/awstats';
	$ConfToChange{'DirIcons'}='/awstatsicons';
	$ConfToChange{'MiscTrackerUrl'}='/awstatsjs/awstats_misc_tracker.js';
}
update_awstats_config("$modelfile");

# Create awstats.conf file
# -----------------------
print "- Create config file '$configfile' for main site...\n";
if (-s $configfile) { print "  Main config file already exists. No change made.\n"; }
else {
	%ConfToChange=();
	if ($OS eq 'linux') { $ConfToChange{'DirData'}='/var/lib/awstats'; }
	if ($OS eq 'windows') { $ConfToChange{'DirData'}='.'; }
	if ($UseAlias) {
		$ConfToChange{'DirCgi'}='/awstats';
		$ConfToChange{'DirIcons'}='/awstatsicons';
		$ConfToChange{'MiscTrackerUrl'}='/awstatsjs/awstats_misc_tracker.js';
	}
	$ConfToChange{'SiteDomain'}='localhost';
	update_awstats_config("$modelfile","$configfile");
}

# Restart Apache if change were made
# ----------------------------------
if ($WebServerChanged) {
	if ($OS eq 'linux') 	{
	 	my $ret=`/usr/bin/service httpd restart`;
	}
	if ($OS eq 'windows')	{
		foreach my $key (keys %ApachePath) {
			if (-f "$key/bin/Apache.exe") {
				print "Restart Apache with '\"$key/bin/Apache.exe\" -k restart'\n";
			 	my $ret=`"$key/bin/Apache.exe" -k restart`;
			}
		}
	}
}


# TODO
# Scan logorate for a log file
# If apache log has a logrotate log found, we create a config and add line in prerotate
# prerotate
#   ...
# endscript
# If not found


# TODO
# Ask to run awstats update process


my $bidon;
print "\n";
print "You should now be able to read your statistics with the following URL:\n";
print "http://localhost/awstats/awstats.pl?config=mysite\n";
print "\n";
print "Press a key to finish...\n";
read STDIN, $bidon, 1;


0;	# Do not remove this line
