#!/usr/bin/perl
#-----------------------------------------------------------------------------
# UrlAlias AWStats plugin
# This plugin allow you to report all URL links with a text title instead of
# URL value.
# You must create a file called urlalias.cnfigvalue.txt and store it in
# plugin directory that contains 2 columns separated by a tab char.
# First column is URL value and second column is text title to use instead of.
#-----------------------------------------------------------------------------
# Perl Required Modules: None
#-----------------------------------------------------------------------------
# $Revision: 1.7 $ - $Author: eldy $ - $Date: 2003-01-06 18:55:09 $


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
my $PluginNeedAWStatsVersion="5.2";
my $PluginHooksFunctions="ReplaceURL";
# ----->

# <-----
# IF YOUR PLUGIN NEED GLOBAL VARIABLES, THEY MUST BE DECLARED HERE.
use vars qw/
$urlaliasloaded
%UrlAliases
/;
# ----->



#-----------------------------------------------------------------------------
# PLUGIN FUNTION Init_pluginname
#-----------------------------------------------------------------------------
sub Init_urlalias {
	my $InitParams=shift;
	my $checkversion=&Check_Plugin_Version($PluginNeedAWStatsVersion);

	# <-----
	# YOU CAN ENTER HERE CODE TO INIT PLUGIN GLOBAL VARIABLES
	debug(" InitParams=$InitParams",1);
	$urlaliasloaded=0;
	%UrlAliases=();
	# ----->

	return ($checkversion?$checkversion:"$PluginHooksFunctions");
}



#-----------------------------------------------------------------------------
# PLUGIN FUNTION ReplaceURL_pluginname
# UNIQUE: NO (Several ReplaceURL can exists for all loaded plugins)
# ReplaceURL is called to add additionnal information for URLs in URLs' report.
#-----------------------------------------------------------------------------
sub ReplaceURL_urlalias {
	# <-----
	if (! $urlaliasloaded) {
		# Load urlalias file
		my $filetoload='';
		if ($SiteConfig && open(URLALIASFILE,"$PluginDir/urlalias.$SiteConfig.txt"))	{ $filetoload="$PluginDir/urlalias.$SiteConfig.txt"; }
		elsif (open(URLALIASFILE,"$PluginDir/urlalias.txt"))  							{ $filetoload="$PluginDir/urlalias.txt"; }
		else { error("Couldn't open UrlAlias file \"$PluginDir/urlalias.txt\": $!"); }
		# This is the fastest way to load with regexp that I know
		%UrlAliases = map(/^([^\t]+)\t+([^\t]+)/o,<URLALIASFILE>);
		close URLALIASFILE;
		debug("UrlAlias file loaded: ".(scalar keys %UrlAliases)." aliases found.");
		$urlaliasloaded=1;
	}
	my $urltoreplace="$_[0]";
	if ($UrlAliases{$urltoreplace}) { print "<font style=\"color: #$color_link; font-weight: bold\">$UrlAliases{$urltoreplace}</font><br>"; }
	else { print ""; }
	return 1;
	# ----->
}


1;	# Do not remove this line
