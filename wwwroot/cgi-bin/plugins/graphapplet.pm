#!/usr/bin/perl
#-----------------------------------------------------------------------------
# GraphApplet AWStats plugin
# Allow AWStats to replace bar graphs with an Applet (awgraphapplet) that draw
# 3D graphs instead.
#-----------------------------------------------------------------------------
# Perl Required Modules: None
#-----------------------------------------------------------------------------
# $Revision: 1.1 $ - $Author: eldy $ - $Date: 2003-11-04 00:59:11 $


# <-----
# ENTER HERE THE USE COMMAND FOR ALL REQUIRED PERL MODULES
# ----->
use strict;no strict "refs";



#-----------------------------------------------------------------------------
# PLUGIN VARIABLES
#-----------------------------------------------------------------------------
# <-----
# ENTER HERE THE MINIMUM AWSTATS VERSION REQUIRED BY YOUR PLUGIN
# AND THE NAME OF ALL FUNCTIONS THE PLUGIN MANAGE.
my $PluginNeedAWStatsVersion="5.91";
my $PluginHooksFunctions="ShowGraph";
# ----->



#-----------------------------------------------------------------------------
# PLUGIN FUNCTION: Init_pluginname
#-----------------------------------------------------------------------------
sub Init_graphapplet {
	my $InitParams=shift;
	my $checkversion=&Check_Plugin_Version($PluginNeedAWStatsVersion);

	# <-----
	# ENTER HERE CODE TO DO INIT PLUGIN ACTIONS
	# ----->

	return ($checkversion?$checkversion:"$PluginHooksFunctions");
}


#-------------------------------------------------------
# PLUGIN FUNCTION: ShowGraph_pluginname
# UNIQUE: YES (Only one plugin using this function can be loaded)
# Add the code for call to applet awgraphapplet
# Parameters:	$title $type $showmonthstats \@blocklabel,\@vallabel,\@valcolor,\@valmax,\@valtotal
# Input:        None
# Output:       HTML code for awgraphapplet insertion
# Return:		0 OK, 1 Error
#-------------------------------------------------------
sub ShowGraph_graphapplet() {
	my $title=shift;
	my $type=shift;
	my $showmonthstats=shift;
	my $blocklabel=shift;
	my $vallabel=shift;
	my $valcolor=shift;
	my $valmax=shift;
	my $valtotal=shift;
	my $valdata=shift;

	my $graphwidth=780;
	my $graphheight=400;
	my $blockspacing=5;
	my $valspacing=1;
	my $valwidth=5;
	my $barsize=0;
	my $blockfontsize=11;
	if ($type eq 'month') 			{ $graphwidth=540; $graphheight=160; $blockspacing=8; $valspacing=0; $valwidth=6; $barsize=$BarHeight; $blockfontsize=11; }
	elsif ($type eq 'daysofmonth')  { $graphwidth=640; $graphheight=160; $blockspacing=3; $valspacing=0; $valwidth=4; $barsize=$BarHeight; $blockfontsize=9; }
	elsif ($type eq 'daysofweeks') 	{ $graphwidth=500; $graphheight=160; $blockspacing=5; $valspacing=0; $valwidth=6; $barsize=$BarHeight; $blockfontsize=11; }
	elsif ($type eq 'hours') 		{ $graphwidth=500; $graphheight=160; $blockspacing=5; $valspacing=0; $valwidth=6; $barsize=$BarHeight; $blockfontsize=11; }
	else { error("Unknown type"); }

#	print "<applet code=\"AWGraphApplet.class\" codebase=\"/classes\" width=\"$graphwidth\" height=\"$graphheight\">\n";
	print "<applet code=\"AWGraphApplet.class\" archive=\"/classes/awgraphapplet.jar\" width=\"$graphwidth\" height=\"$graphheight\">\n";
print <<EOF;
<param name="title" value="$title" />
<param name="awstats_type" value="$type" />
<param name="orientation" value="vertical" />
<param name="barsize" value="$barsize" />
<param name="background_color" value="$color_Background" />
<param name="border_color" value="$color_Background" />
EOF
	print "<param name=\"nbblocks\" value=\"".(scalar @$blocklabel)."\" />\n";
	print "<param name=\"b_fontsize\" value=\"$blockfontsize\" />\n";
	foreach my $i (1..(scalar @$blocklabel)) {
		print "<param name=\"b${i}_label\" value=\"".@$blocklabel[$i-1]."\" />\n";
	}
	print "<param name=\"nbvalues\" value=\"".(scalar @$vallabel)."\" />\n";
	foreach my $i (1..(scalar @$vallabel)) {
		print "<param name=\"v${i}_label\" value=\"".@$vallabel[$i-1]."\" />\n";
		print "<param name=\"v${i}_color\" value=\"".@$valcolor[$i-1]."\" />\n";
		print "<param name=\"v${i}_max\" value=\"".@$valmax[$i-1]."\" />\n";
		print "<param name=\"v${i}_total\" value=\"".@$valtotal[$i-1]."\" />\n";
	}
print <<EOF;
<param name="blockSpacing" value="$blockspacing" />
<param name="valSpacing" value="$valspacing" />
<param name="valwidth" value="$valwidth" />
EOF
	foreach my $j (1..(scalar @$blocklabel)) {
		my $b='';
		foreach my $i (0..(scalar @$vallabel)-1) { $b.=@$valdata[($j-1)*(scalar @$vallabel)+$i]." "; }
		$b=~s/\s$//;
		print "<param name=\"b${j}\" value=\"$b\" />\n";
	}
	print "alt=\"Your browser understands the &lt;APPLET&gt; tag but isn't running the applet.\"\n";
	print "</applet><br />\n";

	return 0;
}



1;	# Do not remove this line
