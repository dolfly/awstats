#!/usr/bin/perl
#-----------------------------------------------------------------------------
# detectwrefererspam AWStats plugin
#-----------------------------------------------------------------------------
# Perl Required Modules: None
#-----------------------------------------------------------------------------
# $Revision: 1.1 $ - $Author: eldy $ - $Date: 2003-06-05 19:32:27 $

# <-----
# ENTER HERE THE USE COMMAND FOR ALL REQUIRED PERL MODULES
# ----->
use strict;no strict "refs";



#-----------------------------------------------------------------------------
# PLUGIN VARIABLES
#-----------------------------------------------------------------------------
my $PluginNeedAWStatsVersion="5.6";
my $PluginHooksFunctions="ScanForRefererSpam";

# <-----
# IF YOUR PLUGIN NEED GLOBAL VARIABLES, THEY MUST BE DECLARED HERE
use vars qw/
/;
# ----->


#-----------------------------------------------------------------------------
# PLUGIN Init_pluginname FUNCTION
#-----------------------------------------------------------------------------
sub Init_detectrefererspam {
	my $InitParams=shift;
	my $checkversion=&Check_Plugin_Version($PluginNeedAWStatsVersion);

	# <-----
	# YOU CAN ENTER HERE CODE TO INIT PLUGIN GLOBAL VARIABLES
	my @param=split(/\s+/,$InitParams);
	# ----->

	return ($checkversion?$checkversion:"$PluginHooksFunctions");
}



#--------------------------------------------------------------------
# Function:      Return true if record is a referer spammer hit
# Input:         
# Output:        
# UNIQUE: YES (Only one plugin using this function can be loaded)
#--------------------------------------------------------------------
sub ScanForRefererSpam_detectrefererspam
{
	debug("Call to ScanForRefererSpam",5);

}



1;	# Ne pas effacer cette ligne
