#!/usr/bin/perl
# view_all.cgi
# Display summary of all available config files
# $Revision: 1.2 $ - $Author: eldy $ - $Date: 2004-12-10 20:50:18 $

require './awstats-lib.pl';
&ReadParse();

# Check if awstats is actually installed
if (!&has_command($config{'awstats'})) {
	&header($text{'index_title'}, "", undef, 1, 1, 0, undef);
	print "<hr>\n";
	print "<p>",&text('index_eawstats', "<tt>$config{'awstats'}</tt>","$gconfig{'webprefix'}/config.cgi?$module_name"),"<p>\n";
	print "<hr>\n";
	&footer("/", $text{'index'});
	exit;
}


&header($text{'viewall_title'}, "", undef, 1, 1, 0, undef, undef, undef, undef);


print <<EOF;
<style type="text/css">
<!--
div { font: 12px 'Arial','Verdana','Helvetica', sans-serif; text-align: justify; }
.CTooltip { position:absolute; top: 0px; left: 0px; z-index: 2; width: 540px; visibility:hidden; font: 8pt 'MS Comic Sans','Arial',sans-serif; background-color: #FFFFE6; padding: 8px; border: 1px solid black; }
//-->
</style>

<script language="javascript" type="text/javascript">
function ShowTip(fArg)
{
	var tooltipOBJ = (document.getElementById) ? document.getElementById('tt' + fArg) : eval("document.all['tt" + fArg + "']");
	if (tooltipOBJ != null) {
		var tooltipLft = (document.body.offsetWidth?document.body.offsetWidth:document.body.style.pixelWidth) - (tooltipOBJ.offsetWidth?tooltipOBJ.offsetWidth:(tooltipOBJ.style.pixelWidth?tooltipOBJ.style.pixelWidth:540)) - 30;
		var tooltipTop = 10;
		if (navigator.appName == 'Netscape') {
			tooltipTop = (document.body.scrollTop>=0?document.body.scrollTop+10:event.clientY+10);
 			tooltipOBJ.style.top = tooltipTop+"px";
			tooltipOBJ.style.left = tooltipLft+"px";
		}
		else {
			tooltipTop = (document.body.scrollTop>=0?document.body.scrollTop+10:event.clientY+10);
			tooltipTop = (document.body.scrollTop>=0?document.body.scrollTop+10:event.clientY+10);
			if ((event.clientX > tooltipLft) && (event.clientY < (tooltipOBJ.scrollHeight?tooltipOBJ.scrollHeight:tooltipOBJ.style.pixelHeight) + 10)) {
				tooltipTop = (document.body.scrollTop?document.body.scrollTop:document.body.offsetTop) + event.clientY + 20;
			}
			tooltipOBJ.style.left = tooltipLft;
			tooltipOBJ.style.top = tooltipTop;
		}
		tooltipOBJ.style.visibility = "visible";
	}
}
function HideTip(fArg)
{
	var tooltipOBJ = (document.getElementById) ? document.getElementById('tt' + fArg) : eval("document.all['tt" + fArg + "']");
	if (tooltipOBJ != null) {
		tooltipOBJ.style.visibility = "hidden";
	}
}
</script>
EOF


print "<hr>\n";

if (! $access{'view'}) {
	print &text('viewall_notallowed')."<br>\n";
}

my @configdirtoscan=split(/\s+/, $access{'dir'});

if (! @configdirtoscan) {
	print &text('index_nodirallowed',"<b>$remote_user</b>")."<br>\n";
	print &text('index_changeallowed',"<a href=\"/acl/\">Webmin - Utilisateurs Webmin</a>", $text{'index_title'})."<br>\n";
	print "<br>\n";
#	print "<p>",&text('index_econfdir', "<tt>$config{'awstats_conf'}</tt>",
#		  "$gconfig{'webprefix'}/config.cgi?$module_name"),"<p>\n";
	print "<hr>\n";
	&footer("/", $text{'index'});
	exit;
}

# Build list of config files from allowed directories
foreach my $dir (split(/\s+/, $access{'dir'})) {
	my @conflist=();
	push(@conflist, map { $_->{'custom'} = 1; $_ } &scan_config_dir($dir));
	foreach my $file (@conflist) {
		next if (!&can_edit_config($file));
		push @config, $file;
	}
}

# Write message for allowed directories
print &text('viewall_allowed',"<b>$remote_user</b>");
print ":<br>\n";
foreach my $dir (split(/\s/,$access{'dir'})) {
	print "$dir<br>";
}
print "<br>\n";
print &text('index_changeallowed',"<a href=\"/acl/\">Webmin - Webmin Users</a>", $text{'index_title'})."<br>\n";
print "<br>";


$starttime=time();
($nowsec,$nowmin,$nowhour,$nowday,$nowmonth,$nowyear,$nowwday,$nowyday) = localtime($starttime);
if ($nowyear < 100) { $nowyear+=2000; } else { $nowyear+=1900; }
$nowmonth++;

my $YearRequired=$in{'year'}||$nowyear;
my $MonthRequired=$in{'month'}||$nowmonth;
my %dirdata=();
my %view_u=();
my %view_v=();
my %view_p=();
my %view_h=();
my %view_k=();
my %notview_p=();
my %notview_h=();
my %notview_k=();
my %ListOfYears=("2004"=>1);
# If required year not in list, we add it
$ListOfYears{$YearRequired}||=$MonthRequired;

# Set dirdata for config file
my $nbofallowedconffound=0;
if (scalar @config) {

	# Loop on each config file
	foreach my $l (@config) {
		next if (!&can_edit_config($l));
		$nbofallowedconffound++;

        # Read data files
        $dirdata{$l}=get_dirdata($l);
    }
}


# Show summary informations
my $nbofallowedconffound=0;
if (scalar @config) {

	# Loop on each config file
	foreach my $l (@config) {
		next if (!&can_edit_config($l));
		$nbofallowedconffound++;
        
		# Head of config file's table list
		if ($nbofallowedconffound == 1) {
			print "<table border width=100%>\n";
			print "<form method=\"post\" action=\"view_all.cgi\">\n";
			print "<tr><td valign=\"middle\"><b>".&text('viewall_period').":</b></td>";
			print "<td valign=\"middle\">";
			print "<select name=\"month\">\n";
			foreach (1..12) { my $monthix=sprintf("%02s",$_); print "<option".($MonthRequired eq "$monthix"?" selected=\"true\"":"")." value=\"$monthix\">".&text("month$monthix")."</option>\n"; }
			print "</select>\n";
			print "<select name=\"year\">\n";
			# Add YearRequired in list if not in ListOfYears
			$ListOfYears{$YearRequired}||=$MonthRequired;
			foreach (sort keys %ListOfYears) { print "<option".($YearRequired eq "$_"?" selected=\"true\"":"")." value=\"$_\">$_</option>\n"; }
			print "</select>\n";
			print "<input type=\"submit\" value=\" Go \" class=\"aws_button\" />";
			print "</td></tr>\n";
            print "</form>\n";
            print "</table>\n";

			print "<table border width=\"100%\">\n";
			print "<tr $tb>";
			print "<td colspan=\"3\"><b>$text{'index_path'}</b></td>";
			print "<td align=center><b>$text{'viewall_u'}</b></td>";
			print "<td align=center><b>$text{'viewall_v'}</b></td>";
			print "<td align=center><b>$text{'viewall_p'}</b></td>";
			print "<td align=center><b>$text{'viewall_h'}</b></td>";
			print "<td align=center><b>$text{'viewall_k'}</b></td>";
			print "</tr>\n";
		}

		# Config file line
		#local @files = &all_config_files($l);
		#next if (!@files);
		local $lconf = &get_config($l);
		my $conf=""; my $dir="";
		if ($l =~ /awstats\.(.*)\.conf$/) { $conf=$1; }
		if ($l =~ /^(.*)[\\\/][^\\\/]+$/) { $dir=$1; }

        # Read data file for config $l
        my $dirdata=$dirdata{$l};
        if (! $dirdata) { $dirdata="."; }
        my $filedata=$dirdata."/awstats$MonthRequired$YearRequired.$conf.txt";

        my $linenb=0;
        my $version=0;
        my $posgeneral=0;
        my $foundendmap=0;
        my $error="";
        if (! -f "$filedata") {
            $error="No data for this month";
        }
        elsif (open(FILE, "<$filedata")) {
            $linenb=0;
            while(<FILE>) {
                if ($linenb++ > 100) { last; }
                my $savline=$_;
                chomp $_; s/\r//;

                # Remove comments not at beginning of line
                $_ =~ s/\s#.*$//;

                # Extract param and value
                my ($param,$value)=split(/=/,CleanFromTags($_),2);
                $param =~ s/^\s+//; $param =~ s/\s+$//;
                $value =~ s/#.*$//;
                $value =~ s/^[\s\'\"]+//; $value =~ s/[\s\'\"]+$//;

                if ($param) {
                    # cleanparam is param without begining #
                    my $cleanparam=$param; my $wascleaned=0;
                    if ($cleanparam =~ s/^#//) { $wascleaned=1; }

                    if ($cleanparam =~ /^AWSTATS DATA FILE (.*)$/) {
                        $version=$1;
                        next;
                    }
                    if ($cleanparam =~ /^POS_GENERAL\s+(\d+)/) {
                        $posgeneral=$1;
                        next;
                    }
                    if ($cleanparam =~ /^END_MAP/) {
                        $foundendmap=1;
                        last;
                    }
                }

            }
            if ($foundendmap) {
                # Map section was completely read, we can jump to data
                if ($posgeneral) {
                    seek(FILE,$posgeneral,0);
            		$linenb=0;
                    while (<FILE>) {
                        if ($linenb++ > 100) { last; }
                        $line=$_;
                 		chomp $line; $line =~ s/\r$//;

                        $view_u{$l}='not yet available';
                        $view_v{$l}='not yet available';
                        $view_p{$l}='not yet available';
                        $view_h{$l}='not yet available';
                        $view_k{$l}='not yet available';
                        $noview_h{$l}='not yet available';
                        $noview_k{$l}='not yet available';

                    }
                } else {
                    $error="Mapping for section GENERAL was wrong";
                }
            }
            close(FILE);
        } else {
            $error="Failed to open $filedata for read";
        }

		my @st=stat($l);
		my $size = $st[7];
		my ($sec,$min,$hour,$day,$month,$year,$wday,$yday) = localtime($st[9]);
		$year+=1900; $month++;

        print '<div class="CTooltip" id="tt'.$nbofallowedconffound.'">';
        printf("Configuration file: <b>%s</b><br>\n",$l);
		printf("Created/Changed: <b>%04s-%02s-%02s %02s:%02s:%02s</b><br>\n",$year,$month,$day,$hour,$min,$sec);
        print "<br>\n";

		my @st2=stat($filedata);
        printf("Data file for period: <b>%s</b><br>\n",$filedata);
        printf("Data file size for period: <b>%s</b> bytes<br>\n",$st2[7]);
        printf("Data file version: <b>%s</b>",($version?" $version":"unknown")."<br>");
        printf("Last update: <b>%s</b>","not yet available");
        print '</div>';

		print "<tr $cb>\n";

		print "<td>$nbofallowedconffound</td>";
        print "<td align=\"center\" width=\"20\" onmouseover=\"ShowTip($nbofallowedconffound);\" onmouseout=\"HideTip($nbofallowedconffound);\"><img src=\"images/info.png\"></td>";
		print "<td>";
        print $l;
		if ($access{'global'}) {	# Edit config
	    	print "<br><a href=\"edit_config.cgi?file=$l\">$text{'index_edit'}</a>";
		}
		print "</td>";

		if ($error) {
		    print "<td colspan=5>";
		    print "$error";
		    print "</td>";
		}
		elsif (! $foundendmap) {
		    print "<td colspan=5>";
		    print "Unable to read summary info in data file. File may have been built by a too old AWStats version. File was built by version: $version.";
		    print "</td>";
		}
        else {
    		print "<td>";
    		print "$view_u{$l}";
    		print "</td>";
    		print "<td>";
    		print "$view_v{$l}";
    		print "</td>";
    		print "<td>";
    		print "$view_p{$l}";
    		print "</td>";
    		print "<td>";
    		print "$view_h{$l}";
    		print "</td>";
    		print "<td>";
    		print "$view_k{$l}";
    		print "</td>";
        }

		print "</tr>\n";
	}

	if ($nbofallowedconffound > 0) { print "</table><br>\n"; }
}

if (! $nbofallowedconffound) {
	print "<br><p><b>$text{'index_noconfig'}</b></p><br>\n";
}

# Back to config list
print "<hr>\n";
&footer("", $text{'index_return'});
