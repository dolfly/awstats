#!/usr/bin/perl
# save_config.cgi
# Save, create or delete options for a config file

require './awstats-lib.pl';
&foreign_require("cron", "cron-lib.pl");
&ReadParse();

&error_setup($text{'save_err'});

if (! $in{'file'}) { $in{'file'}=$in{'new'}; }
if ($in{'new'} && ! $access{'add'}) { &error($text{'edit_ecannot'}); }
if (! $in{'new'} && $access{'edit'}) { &error($text{'edit_ecannot'}); }

&can_edit_config($in{'file'}) || &error($text{'edit_efilecannot'}." ".$in{'file'});


if ($in{'view'}) {
	# Re-direct to the view page
	&redirect("view_config.cgi/".&urlize(&urlize($in{'file'}))."/index.html");
	}
elsif ($in{'delete'}) {
	# Delete this config file from the configuration
	local $cfile = $in{'file'};
	&lock_file($cfile);
	unlink($cfile);
	&unlock_file($cfile);
	&webmin_log("delete", "log", $in{'file'});

	# Create or delete the cron job
#		&lock_file($job->{'file'});
#		&foreign_call("cron", "delete_cron_job", $job);
#		&unlock_file($job->{'file'});

	}
else {
	# Validate and store inputs
	if (!$in{'new'} && !$in{'file'}) { &error($text{'save_efile'}); }
	if ($in{'new'} && -r $in{'$file'}) { &error($text{'save_fileexists'}); }
	my $dir=$in{'file'}; $dir =~ s/[\\\/][^\\\/]+$//;
	if (! $dir) { $dir=$config{'awstats_conf'}; }

	if (! -d $dir) { &error($text{'save_edir'}); }

	%conf=();
	foreach my $key (keys %in) {
		if ($key eq 'file') { next; }
                if ($key eq 'new') { next; }
                if ($key eq 'submit') { next; }
		if ($key eq 'oldfile') { next; }
		$conf{$key} = $in{$key};
		if ($conf{key} ne ' ') {
			$conf{$key} =~ s/^\s+//;
			$conf{$key} =~ s/\s+$//;
		}
	}
	if ($conf{'LogSeparator'} eq '') { $conf{'LogSeparator'}=' '; }

	# Check data
	if (! -r $conf{'LogFile'}) { &error(&text(save_errLogFile,$conf{'LogFile'})); }
	if (! $conf{'SiteDomain'}) { &error(&text(save_errSiteDomain,$conf{'SiteDomain'})); }
	if (! -d $conf{'DirData'}) { &error(&text(save_errDirData,$conf{'DirData'})); }

	if ($in{'new'}) {
		# Add a new config file to the configuration
		&system_logged("cp '$config{'alt_conf'}' '$in{'new'}'");
	}
	
	# Update the config file's options
	local $cfile = $in{'file'};
	&lock_file($cfile);
	&update_config($cfile, \%conf);
	&unlock_file($cfile);
	&webmin_log($in{'new'} ? "create" : "modify", "log", $in{'file'});
	}

&redirect("");

