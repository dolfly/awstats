#!/usr/bin/perl
#-------------------------------------------------------
# Convert a mail log file to a common log file for analyzing with any log
# analyzer.
#-------------------------------------------------------
# Tool built from original work of Odd-Jarle Kristoffersen
# Note 1: QMail must log in syslog format for timestamps to work.
# Note 2: QMail logging is not 100% accurate. Some messages might
# not be logged correctly or completely.
#
# A mail received to 2 different receivers, report 2 records instead of one.
# A mail received to a forwarded account is reported as to the original receiver, not the "forwarded to".
# A mail locally sent to a local alias is reported as n mails to all addresses of alias.
#-------------------------------------------------------
use strict;no strict "refs";


#-------------------------------------------------------
# Defines
#-------------------------------------------------------
use vars qw/ $REVISION $VERSION /;
$REVISION='$Revision: 1.12 $'; $REVISION =~ /\s(.*)\s/; $REVISION=$1;
$VERSION="1.1 (build $REVISION)";

use vars qw/
$DIR $PROG $Extension
$Debug
%mail %qmaildelivery
$help
$mode $year $Debug
$NBOFENTRYFOFLUSH
$MailType
/;

$NBOFENTRYFOFLUSH=8192;		# Nb or records for flush of %entry (Must be a power of 2)
$MailType='';				# Mail server family (postfix, sendmail, qmail)


#-------------------------------------------------------
# Functions
#-------------------------------------------------------

sub error {
	print "Error: $_[0].\n";
    exit 1;
}

sub debug {
	my $level = $_[1] || 1;
	if ($Debug >= $level) { 
		my $debugstring = $_[0];
		if ($ENV{"GATEWAY_INTERFACE"}) { $debugstring =~ s/^ /&nbsp&nbsp /; $debugstring .= "<br>"; }
		print "DEBUG $level - $. - ".time." : $debugstring\n";
		}
	0;
}

sub CleanVadminUser { $_=shift;
	s/[#<|>\[\]]//g;	# Remove unwanted characters first
	s/^(.*?)-//gi;		# Strip off unixuser- at beginning
	return $_;
}

sub CleanEmail { $_=shift;
	s/[#<|>\[\]]//g;	# Remove unwanted characters first
	return $_;
}

# Clean host addresses
# Input:  "servername[123.123.123.123]", "servername [123.123.123.123]"
#         "root@servername", "[123.123.123.123]"
# Return: servername or 123.123.123.123 if servername is 'unknown'
sub CleanHost {
	$_=shift;
	if (/^\[(.*)\]$/) { $_=$1; }						# If [ip] we keep ip
	if (/^unknown\s*\[/) { $_ =~ /\[(.*)\]/; $_=$1; }	# If unknown [ip], we keep ip
	else { $_ =~ s/\s*\[.*$//; }
	$_ =~ s/^.*\@//;									# If x@y, we keep y
	return $_;
}

# Return domain
# Input:	host.domain.com, <user@domain.com>, <>
#
sub CleanDomain { $_=shift;
	s/>.*$//; s/[<>]//g;
	s/^.*@//; 
	if (! $_) { $_ = 'localhost'; }
	return $_;
}

# Return string without starting and ending space
#
sub trim { $_=shift;
	s/^\s+//; s/\s+$//;
	return $_;
}

# Write a record
#
sub OutputRecord {
	my $year=shift;
	my $month=shift;
	my $day=shift;
	my $time=shift;
	my $from=shift;
	my $to=shift;
	my $relay_s=shift;
	my $relay_r=shift;
	my $code=shift;
	my $size=shift||0;
	my $forwardto=shift;

	# Clean day and month
	$day=sprintf("%02d",$day);
	if ($month eq 'Jan') { $month = "01"; }
	if ($month eq 'Feb') { $month = "02"; }
	if ($month eq 'Mar') { $month = "03"; }
	if ($month eq 'Apr') { $month = "04"; }
	if ($month eq 'May') { $month = "05"; }
	if ($month eq 'Jun') { $month = "06"; }
	if ($month eq 'Jul') { $month = "07"; }
	if ($month eq 'Aug') { $month = "08"; }
	if ($month eq 'Sep') { $month = "09"; }
	if ($month eq 'Oct') { $month = "10"; }
	if ($month eq 'Nov') { $month = "11"; }
	if ($month eq 'Dec') { $month = "12"; }

	# Clean from
	$from=&CleanEmail($from);
	$from||='<>';
	
	# Clean to
	if ($mode eq 'vadmin') { $to=&CleanVadminUser($to); }
	else { $to=&CleanEmail($to); }
	$to||='<>';

	# Clean relay_s
	$relay_s=&CleanHost($relay_s);
	$relay_s||=&CleanDomain($from);
	$relay_s=~s/\.$//;
	if ($relay_s eq 'local' || $relay_s eq 'localhost.localdomain') { $relay_s='localhost'; }

	# Clean relay_r
	$relay_r=&CleanHost($relay_r);
	$relay_r||="-";
	$relay_r=~s/\.$//;
	if ($relay_r eq 'local' || $relay_r eq 'localhost.localdomain') { $relay_r='localhost'; }
	#if we don't have info for relay_s, we keep it unknown, awstats might then guess it
	
	# Write line
	print "$year-$month-$day $time $from $to $relay_s $relay_r SMTP - $code $size\n";
	
	# If there was a redirect
	if ($forwardto) {
		# Redirect to local address
		# TODO
		# Redirect to external address
		# TODO
	}
}



#-------------------------------------------------------
# MAIN
#-------------------------------------------------------

# Prepare QueryString
my %param=();
for (0..@ARGV-1) { $param{$_}=$ARGV[$_]; }
foreach my $key (sort keys %param) {
	if ($param{$key} =~ /(^|-|&)debug=([^&]+)/i) { $Debug=$2; shift; next; }
	if ($param{$key} =~ /^(\d+)$/) { $year=$1; shift; next; }
	if ($param{$key} =~ /^(standard|vadmin)$/i) { $mode=$1; shift; next; }
}
if ($mode ne 'standard' and $mode ne 'vadmin') { $help = 1; }

($DIR=$0) =~ s/([^\/\\]*)$//; ($PROG=$1) =~ s/\.([^\.]*)$//; $Extension=$1;

my $starttime=time();
my ($nowsec,$nowmin,$nowhour,$nowday,$nowmonth,$nowyear,$nowwday,$nowyday) = localtime($starttime);
$year||=($nowyear+1900);

# Show usage help
if ($help) {
	print "----- $PROG $VERSION -----\n";
	print <<HELPTEXT;
$PROG is mail log preprocessor that convert a mail log file (from
postfix, sendmail or qmail servers) into a human readable format.
The output format is also ready to be used by a log analyzer, like AWStats.

Usage:
  perl maillogconvert.pl [standard|vadmin] [year] < logfile > output

The first parameter specifies what format the mail logfile is :
  standard - logfile is standard postfix,sendmail or qmail log format
  vadmin   - logfile is qmail log format with vadmin multi-host support

The second parameter specifies what year to timestamp logfile with, if current
year is not the correct one (ie. 2002). Always use 4 digits. If not specified,
current year is used.

If no output is specified, it goes to the console (stdout).

HELPTEXT
	sleep 1;
	exit;
}

#
# Start Processing Input Logfile
#
my $numrecord=0;
my $numrecordforflush=0;
while (<>) {
	chomp $_; s/\r//;
	$numrecord++;
	$numrecordforflush++;

	my $mailid=0;

	if (/^__BREAKPOINT__/) { last; }	# For debug only

	if (/^#/) {
		debug("Comment record");
		next;
	}
	
	#
	# Get sender host for postfix
	#
	elsif (/: client=/ ne undef) {
		$MailType||='postfix';
		my ($id,$relay_s)=m/\w+\s+\d+\s+\d+:\d+:\d+\s+[\w\-]+\s+(?:sendmail|postfix\/smtpd|postfix\/smtp)\[\d+\]:\s+(.*?):\s+client=(.*)/;
		$mailid=$id;
		$mail{$id}{'relay_s'}=$relay_s;
		debug("For id=$id, found host sender on a 'client' line: $mail{$id}{'relay_s'}");
	}

	#
	# See if we received postfix email reject error
	#
	elsif (/: reject/ ne undef) {
		$MailType||='postfix';
		# Example: 
		# postfix:  Jan 01 04:19:04 apollon postfix/smtpd[26553]: 1954F3B8A4: reject: RCPT from unknown[80.245.33.2]: 450 <partenaires@chiensderace.com>: User unknown in local recipient table; from=<httpd@fozzy2.dpi-europe.fr> to=<partenaires@chiensderace.com> proto=ESMTP helo=<fozzy2.dpi-europe.fr>
		# postfix:  Jan 01 04:26:39 halley postfix/smtpd[9245]: reject: RCPT from unknown[203.156.32.33]: 554 <charitha99@yahoo.com>: Recipient address rejected: Relay access denied; from=<1126448365@aol.com> to=<charitha99@yahoo.com>
		my ($mon,$day,$time,$id,$code,$from,$to)=m/(\w+)\s+(\d+)\s+(\d+:\d+:\d+)\s+[\w\-]+\s+(?:postfix\/smtpd|postfix\/smtp)\[\d+\]:\s+(.*?):\s+(.*)\s+from=([^\s,]*)\s+to=([^\s,]*)/;
		$mailid=($id eq 'reject'?999:$id);	# id not provided in log, we take 999
		# $code='reject: RCPT from c66.191.66.89.dul.mn.charter.com[66.191.66.89]: 450 <partenaires@chiensderace.com>: User unknown in local recipient table;'
		#    or 'reject: RCPT from unknown[203.156.32.33]: 554 <charitha99@yahoo.com>: Recipient address rejected: Relay access denied;'
		if ($mailid) {
			if ($code =~ /\s+(\d\d\d)\s+/) { $mail{$mailid}{'code'}=$1; }
			else { $mail{$mailid}{'code'}=999; }	# Unkown error
			if (! $mail{$mailid}{'relay_s'} &&  $code =~ /from\s+([^\s]+)\s+/) {
				$mail{$mailid}{'relay_s'}=&trim($1);
			}
			$mail{$mailid}{'from'}=&trim($from);
			$mail{$mailid}{'to'}=&trim($to);
			$mail{$mailid}{'mon'}=$mon;
			$mail{$mailid}{'day'}=$day;
			$mail{$mailid}{'time'}=$time;
			debug("For id=$mailid, found a postfix error incoming message: code=$mail{$mailid}{'code'} from=$mail{$mailid}{'from'} to=$mail{$mailid}{'to'}");
		}
	}
	#
	# See if we received sendmail reject error
	#
	elsif (/, reject/ ne undef) {
		$MailType||='sendmail';
		# Example: 
		# sm-mta:   Jul 27 04:06:05 androneda sm-mta[6641]: h6RB44tg006641: ruleset=check_mail, arg1=<7ms93d4ms@topprodsource.com>, relay=crelay1.easydns.com [216.220.57.222], reject=451 4.1.8 Domain of sender address 7ms93d4ms@topprodsource.com does not resolve
		# sm-mta:	Jul 27 06:21:24 androneda sm-mta[11461]: h6RDLNtg011461: ruleset=check_rcpt, arg1=<nobody@nova.dice.net>, relay=freedom.myhostdns.com [66.246.77.42], reject=550 5.7.1 <nobody@nova.dice.net>... Relaying denied
		# sendmail: Sep 30 04:21:32 halley sendmail[3161]: g8U2LVi03161: ruleset=check_rcpt, arg1=<amber3624@netzero.net>, relay=moon.partenor.fr [10.0.0.254], reject=550 5.7.1 <amber3624@netzero.net>... Relaying denied
		my ($mon,$day,$time,$id,$ruleset,$arg,$relay_s,$code)=m/(\w+)\s+(\d+)\s+(\d+:\d+:\d+)\s+[\w\-]+\s+(?:sendmail|sm-mta)\[\d+\]:\s+(.*?):\sruleset=(\w+),\s+arg1=(.*),\s+relay=(.*),\s+(reject=.*)/;
		$mailid=$id;
		if ($mailid) {
			if ($ruleset eq 'check_mail') { $mail{$id}{'from'}=$arg; }
			if ($ruleset eq 'check_rcpt') { $mail{$id}{'to'}=$arg; }
			$mail{$id}{'relay_s'}=$relay_s;
			# $code='reject=550 5.7.1 <amber3624@netzero.net>... Relaying denied'
			if ($code =~ /=(\d\d\d)\s+/) { $mail{$id}{'code'}=$1; }
			else { $mail{$id}{'code'}=999; }	# Unkown error
			$mail{$id}{'mon'}=$mon;
			$mail{$id}{'day'}=$day;
			$mail{$id}{'time'}=$time;
			debug("For id=$id, found a sendmail error incoming message: code=$mail{$id}{'code'} from=$mail{$id}{'from'} to=$mail{$id}{'to'} relay_s=$mail{$id}{'relay_s'}");
		}
	}
	#
	# See if we received postfix email bounced error
	#
	elsif (/stat(us)?=bounced/ ne undef) {
		$MailType||='postfix';
		# Example: 
		# postfix:  Sep  9 18:24:23 halley postfix/local[22003]: 12C6413EC9: to=<etavidian@partenor.com>, relay=local, delay=0, status=bounced (unknown user: "etavidian")
		my ($mon,$day,$time,$id,$to,$relay_r)=m/(\w+)\s+(\d+)\s+(\d+:\d+:\d+)\s+[\w\-]+\s+(?:postfix\/(?:local|smtpd|smtp))\[\d+\]:\s+(.*?):\s+to=([^\s,]*)[\s,]+relay=([^\s,]*)/;
		$mailid=($id eq 'reject'?999:$id);	# id not provided in log, we take 999
		if ($mailid) {
			$mail{$mailid}{'code'}="999";	# Unkown error (bounced)
			$mail{$mailid}{'to'}=&trim($to);
			$mail{$mailid}{'relay_r'}=&trim($relay_r);
			$mail{$mailid}{'mon'}=$mon;
			$mail{$mailid}{'day'}=$day;
			$mail{$mailid}{'time'}=$time;
			debug("For id=$mailid, found a postfix bounced incoming message: code=$mail{$mailid}{'code'} to=$mail{$mailid}{'to'} relay_r=$mail{$mailid}{'relay_r'}");
		}
	}

	#
 	# See if we send a sendmail (with ctladdr tag) email
 	#
 	elsif(/, ctladdr=/ ne undef) {
		$MailType||='sendmail';
		#
		# Matched outgoing sendmail/postfix message
		#
		my ($mon,$day,$time,$id,$to,$from)=m/(\w+)\s+(\d+)\s+(\d+:\d+:\d+)\s+[\w\-]+\s+(?:sm-mta|sendmail(?:-out|)|postfix\/(?:local|smtpd|smtp))\[.*?\]:\s+([^:]*):\s+to=(.*?)[,\s]+ctladdr=([^\,\s]*)/;
		$mailid=$id;
		if (m/\s+relay=([^\s,]*)[\s,]/) { $mail{$id}{'relay_r'}=$1; }
		elsif (m/\s+mailer=local/) { $mail{$id}{'relay_r'}='localhost'; }
		if (/, stat\=Sent/) { $mail{$id}{'code'}=1; }
		elsif (/, stat\=User\s+unknown/) { $mail{$id}{'code'}=550; }
		elsif (/, stat\=Local\s+configuration/) { $mail{$id}{'code'}=451; }
		elsif (/, stat\=Deferred:\s+(\d*)/) { $mail{$id}{'code'}=$1; }
		else { $mail{$id}{'code'}=999; }
		$mail{$id}{'mon'}=$mon;
		$mail{$id}{'day'}=$day;
		$mail{$id}{'time'}=$time;
		$mail{$id}{'to'}=&trim($to);
		$mail{$id}{'from'}=&trim($from);
		$mail{$id}{'size'}='?';
		debug("For id=$id, found a sendmail outgoing message: to=$mail{$id}{'to'} from=$mail{$id}{'from'} size=$mail{$id}{'size'} relay_s=$mail{$id}{'relay_s'}");
 	}

	#
	# Matched incoming qmail message
	#
	elsif (/info msg .* from/ ne undef) {
		# Example: Sep 14 09:58:09 gandalf qmail: 1063526289.292776 info msg 270182: bytes 10712 from <john@john.do> qp 54945 uid 82
		$MailType||='qmail';
		#my ($id,$size,$from)=m/(\d+)(?:\.\d+)? info msg \d+: bytes (\d+) from <(.*)>/;
		my ($id,$size,$from)=m/\d+(?:\.\d+)? info msg (\d+): bytes (\d+) from <(.*)>/;
		$mailid=$id;
		delete $mail{$mailid};	# If 'info msg' found, we start a new mail. This is to protect from wrong file
		if ($mail{$id}{'from'} ne '<>') { $mail{$id}{'from'}=$from; }	# TODO ???
		$mail{$id}{'size'}=$size;
		if (m/\s+relay=([^\,]+)[\s\,]/ || m/\s+relay=([^\s\,]+)$/) { $mail{$id}{'relay_s'}=$1; }
		debug("For id=$id, found a qmail 'info msg' message: from=$mail{$id}{'from'} size=$mail{$id}{'size'} relay_s=$mail{$id}{'relay_s'}");
	}

	#
	# Matched incoming sendmail or postfix message
	#
	elsif (/: from=/ ne undef) {
		# sm-mta:  Jul 28 06:55:13 androneda sm-mta[28877]: h6SDtCtg028877: from=<4cmkh79eob@webtv.net>, size=2556, class=0, nrcpts=1, msgid=<w1$kqj-9-o2m45@0h2i38.4.m0.5u>, proto=ESMTP, daemon=MTA, relay=smtp.easydns.com [205.210.42.50]
		# postfix: Jul  3 15:32:26 apollon postfix/qmgr[13860]: 08FB63B8A4: from=<nobody@ns3744.ovh.net>, size=3302, nrcpt=1 (queue active)
		my ($id,$from,$size)=m/\w+\s+\d+\s+\d+:\d+:\d+\s+[\w\-]+\s+(?:sm-mta|sendmail(?:-in|)|postfix\/qmgr|postfix\/nqmgr)\[\d+\]:\s+(.*?):\s+from=(.*?),\s+size=(.*?),/;
		$mailid=$id;
		if (! $mail{$id}{'code'}) { $mail{$id}{'code'}=1; }	# If not already defined, we define it
		if ($mail{$id}{'from'} ne '<>') { $mail{$id}{'from'}=$from; }
		$mail{$id}{'size'}=$size;
		if (m/\s+relay=([^\,]+)[\s\,]/ || m/\s+relay=([^\s\,]+)$/) { $mail{$id}{'relay_s'}=$1; }
		debug("For id=$id, found a sendmail/postfix incoming message: from=$mail{$id}{'from'} size=$mail{$id}{'size'} relay_s=$mail{$id}{'relay_s'}");
	}

	#
	# Matched sendmail/postfix "to" message
	#
	elsif (/: to=.*stat(us)?=sent/i ne undef) {
		my ($mon,$day,$time,$id,$to)=m/(\w+)\s+(\d+)\s+(\d+:\d+:\d+)\s+[\w\-]+\s+(?:sm-mta|sendmail(?:-out|)|postfix\/(?:local|smtpd|smtp))\[.*?\]:\s+(.*?):\s+to=(.*?),/;
		$mailid=$id;
		$mail{$id}{'code'}='1';
		if (m/\s+relay=([^\s,]*)[\s,]/) { $mail{$id}{'relay_r'}=$1; }
		elsif (m/\s+mailer=local/) { $mail{$id}{'relay_r'}='localhost'; }
		if (m/forwarded as/) {
			# If 'forwarded as idnewmail' is found, we discard this mail to avoid counting it twice
			debug("For id=$id, mail was forwarded to other id, we discard it");
			delete $mail{$id};
		}
		else {
			if (m/\s+orig_to=([^\s,]*)[\s,]/) {
				# If we have a orig_to, we used it as receiver
				$mail{$id}{'to'}=&trim($1);
				$mail{$id}{'forwardedto'}=&trim($to);
			}
			else {
				$mail{$id}{'to'}=&trim($to);
			}
			$mail{$id}{'mon'}=$mon;
			$mail{$id}{'day'}=$day;
			$mail{$id}{'time'}=$time;
			debug("For id=$id, found a sendmail/postfix record: mon=$mail{$id}{'mon'} day=$mail{$id}{'day'} time=$mail{$id}{'time'} to=$mail{$id}{'to'} relay_r=$mail{$id}{'relay_r'}");
		}
	}

	#
	# Matched qmail "to" record
	#
	elsif (/starting delivery/ ne undef) {
		# Example: Sep 14 09:58:09 gandalf qmail: 1063526289.574100 starting delivery 251: msg 270182 to local spamreport@john.do
		$MailType||='qmail';
		#my ($mon,$day,$time,$id,$to)=m/^(\w+)\s+(\d+)\s+(\d+:\d+:\d+)\s+.*\s+(\d+)(?:\.\d+)?\s+starting delivery \d+:\s+msg\s+\d+\s+to\s+.*?\s+(.*)$/;
		my ($mon,$day,$time,$delivery,$id,$to)=m/^(\w+)\s+(\d+)\s+(\d+:\d+:\d+)\s+.*\s+\d+(?:\.\d+)?\s+starting delivery (\d+):\s+msg\s+(\d+)\s+to\s+.*?\s+(.*)$/;
		$mailid=$id;
		if (m/\s+relay=([^\s,]*)[\s,]/) { $mail{$id}{'relay_r'}=$1; }
		elsif (m/\s+mailer=local/) { $mail{$id}{'relay_r'}='localhost'; }
		$qmaildelivery{$delivery}=$id;		# Save mail id for this delivery to be able to get error code
		$mail{$id}{'mon'}=$mon;
		$mail{$id}{'day'}=$day;
		$mail{$id}{'time'}=$time;
		$mail{$id}{'to'}{$delivery}=&trim($to);
		debug("For id=$id, found a qmail 'start delivery' record: mon=$mail{$id}{'mon'} day=$mail{$id}{'day'} time=$mail{$id}{'time'} to=$mail{$id}{'to'}{$delivery} relay_r=$mail{$id}{'relay_r'} delivery=$delivery");
	}

	#
	# Matched qmail status code record
	#
	elsif (/delivery (\d+): (\w+):/ ne undef) {
		# Example: Sep 14 09:58:09 gandalf qmail: 1063526289.744259 delivery 251: success: did_0+0+1/
		$MailType||='qmail';
		my ($delivery,$code)=($1,$2);
		my $id=$qmaildelivery{$delivery};
		$mailid=$id;
		if ($code =~ /success/i) { $mail{$id}{'code'}{$delivery}=1; }
		elsif ($code =~ /deferral/i) { $mail{$id}{'code'}{$delivery}=999; }
		else { $mail{$id}{'code'}{$delivery}=999; }
		debug("For id=$qmaildelivery{$delivery}, found a qmail 'delivery' record: delivery=$delivery code=$mail{$id}{'code'}{$delivery}");
	}
	#
	# Matched qmail end of mail record
	#
	elsif (/end msg (\d+)/ && scalar %{$mail{$1}{'to'}}) {	# If records for mail id are finished and still mails with no delivery status
		# Example: Sep 14 09:58:12 gandalf qmail: 1063526292.782444 end msg 270182
		$MailType||='qmail';
		my ($id)=($1);
		$mailid=$id;
		foreach my $delivery (keys %{$mail{$mailid}{'to'}}) { $mail{$id}{'code'}{$delivery}||=1; }
		debug("For id=$id, found a qmail 'end msg' record. This replace 'delivery' record for delivery=".join(',',keys %{$mail{$id}{'code'}}));
	}

	#
	# Write record if all required data were found
	#
	if ($mailid) {
		my $code; my $to;
		my $delivery=0;
		my $canoutput=0;
		
		debug("ID:$mailid RELAY_S:$mail{$mailid}{'relay_s'} RELAY_R:$mail{$mailid}{'relay_r'} FROM:$mail{$mailid}{'from'} TO:$mail{$mailid}{'to'} CODE:$mail{$mailid}{'code'}");

		# Check if we can output a mail line
		if ($MailType eq 'qmail') {
			if (scalar %{$mail{$mailid}{'code'}}) {
				# This is a hash variable
				foreach my $key (keys %{$mail{$mailid}{'code'}}) {
					$delivery=$key;
					$code=$mail{$mailid}{'code'}{$key};
					$to=$mail{$mailid}{'to'}{$key};
				}
				$canoutput=1;
			}
		}
		if ($MailType ne 'qmail') {
			$code=$mail{$mailid}{'code'};
			$to=$mail{$mailid}{'to'};
			if ($mail{$mailid}{'from'} && $mail{$mailid}{'to'}) { $canoutput=1; }
			if ($mail{$mailid}{'from'} && $mail{$mailid}{'code'} > 1) { $canoutput=1; }
		}

		# If we can
		if ($canoutput) {
			&OutputRecord($year,$mail{$mailid}{'mon'},$mail{$mailid}{'day'},$mail{$mailid}{'time'},$mail{$mailid}{'from'},$to,$mail{$mailid}{'relay_s'},$mail{$mailid}{'relay_r'},$code,$mail{$mailid}{'size'},$mail{$mailid}{'forwardto'});
			# Delete mail with generic unknown id (This id can by used by another mail)
			if ($mailid == 999) {
				debug(" Delete mail for id=$mailid",3);
				delete $mail{$mailid};
			}
			# Delete delivery instance for id if qmail (qmail can use same id for several mails with multiple delivery)
			elsif ($MailType eq 'qmail') {
				debug(" Delete delivery instances for mail id=$mailid and delivery id=$delivery",3);
				if ($delivery) {
					delete $mail{$mailid}{'to'}{$delivery};
					delete $mail{$mailid}{'code'}{$delivery};
				}
			}

			# We flush %mail if too large
			if (scalar keys %mail > $NBOFENTRYFOFLUSH) {
				debug("We reach $NBOFENTRYFOFLUSH records in %mail, so we flush mail hash array");
				#foreach my $id (keys %mail) {
				#	debug(" Delete mail for id=$id",3);
				#	delete $mail{$id};
				#}
				%mail=();
				%qmaildelivery=();
			}

		}
	}
	else {
		debug("Not interesting row");
	}

}

#foreach my $key (keys %mail) {
#	print ".$key.$mail{$key}{'to'}.\n";
#}

0;
