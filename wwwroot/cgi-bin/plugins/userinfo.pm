#!/usr/bin/perl
#-----------------------------------------------------------------------------
# UserInfo AWStats plugin
# This plugin allow you to add information on authenticated users chart from
# a text file. Like full user name and lastname.
# You must create a file called userinfo.configvalue.txt and store it in
# plugin directory that contains 2 columns separated by a tab char.
# First column is authenticated user login and second column is text
# you want add.
#-----------------------------------------------------------------------------
# Perl Required Modules: None
#-----------------------------------------------------------------------------
# $Revision: 1.1 $ - $Author: eldy $ - $Date: 2003-04-26 19:26:38 $


# <-----
# ENTER HERE THE USE COMMAND FOR ALL REQUIRED PERL MODULES.
# ----->
use strict;no strict "refs";



#-----------------------------------------------------------------------------
# PLUGIN VARIABLES
#-----------------------------------------------------------------------------
# <-----
# ENTER HERE THE MINIMUM AWSTATS VERSION REQUIRED BY YOUR PLUGIN
# AND THE NAME OF ALL FUNCTIONS THE PLUGIN MANAGE.
my $PluginNeedAWStatsVersion="5.5";
my $PluginHooksFunctions="ShowInfoUser";
# ----->

# <-----
# IF YOUR PLUGIN NEED GLOBAL VARIABLES, THEY MUST BE DECLARED HERE.
use vars qw/
$userinfoloaded
%UserInfo
/;
# ----->



#-----------------------------------------------------------------------------
# PLUGIN FUNCTION: Init_pluginname
#-----------------------------------------------------------------------------
sub Init_userinfo {
	my $InitParams=shift;
	my $checkversion=&Check_Plugin_Version($PluginNeedAWStatsVersion);

	# <-----
	# ENTER HERE CODE TO DO INIT PLUGIN ACTIONS
	debug(" InitParams=$InitParams",1);
	$userinfoloaded=0;
	%UserInfo=();
	# ----->

	return ($checkversion?$checkversion:"$PluginHooksFunctions");
}



#-----------------------------------------------------------------------------
# PLUGIN FUNCTION: ShowInfoUser_pluginname
# UNIQUE: NO (Several plugins using this function can be loaded)
# Function called to add additionnal information for Users in users' report.
# Parameters: URL
#-----------------------------------------------------------------------------
sub ShowInfoUser_userinfo {
	# <-----
	if (! $userinfoloaded) {
		# Load userinfo file
		my $filetoload='';
		if ($SiteConfig && open(USERINFOFILE,"$PluginDir/userinfo.$SiteConfig.txt"))	{ $filetoload="$PluginDir/userinfo.$SiteConfig.txt"; }
		elsif (open(USERINFOFILE,"$PluginDir/userinfo.txt"))  							{ $filetoload="$PluginDir/userinfo.txt"; }
		else { error("Couldn't open UserInfo file \"$PluginDir/userinfo.txt\": $!"); }
		# This is the fastest way to load with regexp that I know
		%UserInfo = map(/^([^\t]+)\t+([^\t]+)/o,<USERINFOFILE>);
		close USERINFOFILE;
		debug("UserInfo file loaded: ".(scalar keys %UserInfo)." entries found.");
		$userinfoloaded=1;
	}
	my $userinfotoreplace="$_[0]";
	if ($UserInfo{$userinfotoreplace}) { print "<TD>$UserInfo{$userinfotoreplace}</TD>"; }
	else { print "<TD>&nbsp;</TD>"; }
	return 1;
	# ----->
}


1;	# Do not remove this line
