#!/usr/bin/perl
#-----------------------------------------------------------------------------
# Rawlog AWStats plugin
# This plugin adds a form in AWStats main page to allow users to see raw
# content of current log files. A filter is also available.
#-----------------------------------------------------------------------------
# Perl Required Modules: None
#-----------------------------------------------------------------------------
# $Revision: 1.1 $ - $Author: eldy $ - $Date: 2003-08-03 15:25:26 $


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
my $PluginNeedAWStatsVersion="5.7";
my $PluginHooksFunctions="AddHTMLBodyHeader BuildFullHTMLOutput";
# ----->

# <-----
# IF YOUR PLUGIN NEED GLOBAL VARIABLES, THEY MUST BE DECLARED HERE.
use vars qw/
$MAXLINE
/;
# ----->



#-----------------------------------------------------------------------------
# PLUGIN FUNCTION: Init_pluginname
#-----------------------------------------------------------------------------
sub Init_rawlog {
	my $InitParams=shift;
	my $checkversion=&Check_Plugin_Version($PluginNeedAWStatsVersion);

	# <-----
	# ENTER HERE CODE TO DO INIT PLUGIN ACTIONS
	debug(" InitParams=$InitParams",1);
	$MAXLINE=5000;
	# ----->

	return ($checkversion?$checkversion:"$PluginHooksFunctions");
}



#-----------------------------------------------------------------------------
# PLUGIN FUNTION: AddHTMLBodyHeader_pluginname
# UNIQUE: NO (Several plugins using this function can be loaded)
# Function called to Add HTML code at beginning of BODY section.
#-----------------------------------------------------------------------------
sub AddHTMLBodyHeader_rawlog {
	# <-----
	# Show form
	&_ShowForm('');
	return 1;
	# ----->
}


#-----------------------------------------------------------------------------
# PLUGIN FUNTION: BuildFullHTMLOutput_pluginname
# UNIQUE: NO (Several plugins using this function can be loaded)
# Function called to output an HTML page completely built by plugin instead
# of AWStats output
#-----------------------------------------------------------------------------
sub BuildFullHTMLOutput_rawlog {
	# <-----
	my $Filter='';
	if ($QueryString =~ /filterrawlog=([^&]+)/i) { $Filter=&DecodeEncodedString("$1"); }

	# Show form
	&_ShowForm($Filter);

	print "<hr>\n";
	
	# Show raws
	open(LOG,"$LogFile") || error("Couldn't open server log file \"$LogFile\" : $!");
	binmode LOG;	# Avoid premature EOF due to log files corrupted with \cZ or bin chars
	my $i=0;
	while (<LOG>) {
		chomp $_; $_ =~ s/\r//;
		
		if ($Filter) {
			if ($_ !~ m/$Filter/i) { next; }
		}
		print "$_<br>";
		$i++;
		if ($i > $MAXLINE) { last; }
	}
	print "<b>$i lines.</b><br>";
	return 1;
	# ----->
}

sub _ShowForm {
	my $Filter=shift||'';
	print "<br>\n";
	print "<form action=\"$AWScript\" style=\"padding: 0px 0px 0px 0px; margin-top: 0\" target=>\n";
	print "<TABLE CLASS=\"AWS_BORDER\" BORDER=0 CELLPADDING=2 CELLSPACING=0 WIDTH=\"100%\">\n";
	print "<TR><TD>";
	print "<TABLE CLASS=\"AWS_DATA\" BORDER=0 CELLPADDING=1 CELLSPACING=0 WIDTH=\"100%\">\n";
	print "<tr align=left><td align=left><b>Show content of file '$LogFile' ($MAXLINE first lines):</b></td></tr>\n";
	print "<tr align=left><td align=left>$Message[79]: <input type=text name=filterrawlog value=\"$Filter\"><input type=submit value=\"List\" class=\"AWS_BUTTON\">\n";
	print "<input type=hidden name=framename value=\"$FrameName\"><input type=hidden name=pluginmode value=\"rawlog\">";
	print "</td></tr>\n";
	print "</TABLE>\n";
	print "</TD></TR></TABLE>\n";
	print "</form>\n";
}

1;	# Do not remove this line
