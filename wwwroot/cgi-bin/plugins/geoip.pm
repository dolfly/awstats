#!/usr/bin/perl
#-----------------------------------------------------------------------------
# GeoIp AWStats plugin
# This plugin allow you to get AWStats country report with countries detected
# from a Geographical database (GeoIP internal database) instead of domain
# hostname suffix.
#-----------------------------------------------------------------------------
# Perl Required Modules: Geo::IP
#-----------------------------------------------------------------------------
# $Revision: 1.4 $ - $Author: eldy $ - $Date: 2003-01-11 15:43:40 $


# <-----
# ENTER HERE THE USE COMMAND FOR ALL REQUIRED PERL MODULES
use Geo::IP;				# For GeoIP
#use Geo::IPfree;			# For GeoIPfree
# ----->
use strict;no strict "refs";



#-----------------------------------------------------------------------------
# PLUGIN VARIABLES
#-----------------------------------------------------------------------------
# <-----
# ENTER HERE THE MINIMUM AWSTATS VERSION REQUIRED BY YOUR PLUGIN
# AND THE NAME OF ALL FUNCTIONS THE PLUGIN MANAGE.
my $PluginNeedAWStatsVersion="5.4";
my $PluginHooksFunctions="GetCountryCodeByAddr GetCountryCodeByName";
# ----->

# <-----
# IF YOUR PLUGIN NEED GLOBAL VARIABLES, THEY MUST BE DECLARED HERE.
use vars qw/
%TmpDomainLookup
$gi
/;
# ----->


# For manual test
#$gi = Geo::IPfree::new();
# 10.230.17.130 -> us   80.8.56.15 -> fr
#my ($res,undef)=$gi->LookUp("80.8.56.15"); if ($res !~ /\w\w/) { $res='ip'; }
#print $res;


#-----------------------------------------------------------------------------
# PLUGIN FUNTION Init_pluginname
#-----------------------------------------------------------------------------
sub Init_geoip {
	my $InitParams=shift;
	my $checkversion=&Check_Plugin_Version($PluginNeedAWStatsVersion);

	# <-----
	# YOU CAN ENTER HERE CODE TO INIT PLUGIN GLOBAL VARIABLES
	debug(" InitParams=$InitParams",1);
	%TmpDomainLookup=();
	$gi = Geo::IP->new(GEOIP_MEMORY_CACHE);		# For GeoIP	(Can also use GEOIP_STANDARD)
#	$gi = Geo::IPfree::new();					# For GeoIPfree
	# ----->

	return ($checkversion?$checkversion:"$PluginHooksFunctions");
}


#-----------------------------------------------------------------------------
# PLUGIN FUNTION GetCountryCodeByName_pluginname
# UNIQUE: YES (Only one function GetCountryName can exists for all loaded plugins)
# GetCountryCodeByName is called to translate a host name into a country name.
#-----------------------------------------------------------------------------
sub GetCountryCodeByName_geoip {
	# <-----
	my $res=$TmpDomainLookup{$_[0]}||'';
	if (! $res) {
		$res=lc($gi->country_code_by_name($_[0]));								# For GeoIP
#		($res,undef)=$gi->LookUp($_[0]); if ($res !~ /\w\w/) { $res='ip'; }		# For GeoIPfree
		$TmpDomainLookup{$_[0]}=$res;
		if ($Debug) { debug(" GetCountryCodeByName for $_[0]: $res",5); }
	}
	elsif ($Debug) { debug(" GetCountryCodeByName for $_[0]: Already resolved to $res",5); }
	return $res;
	# ----->
}

#-----------------------------------------------------------------------------
# PLUGIN FUNTION GetCountryCodeByAddr_pluginname
# UNIQUE: YES (Only one function GetCountryName can exists for all loaded plugins)
# GetCountryCodeByAddr is called to translate an ip into a country name.
#-----------------------------------------------------------------------------
sub GetCountryCodeByAddr_geoip {
	# <-----
	my $res=$TmpDomainLookup{$_[0]}||'';
	if (! $res) {
		$res=lc($gi->country_code_by_addr($_[0]));								# For GeoIP
#		($res,undef)=$gi->LookUp($_[0]); if ($res !~ /\w\w/) { $res='ip'; }		# For GeoIPfree
		$TmpDomainLookup{$_[0]}=$res;
		if ($Debug) { debug(" GetCountryCodeByAddr for $_[0]: $res",5); }
	}
	elsif ($Debug) { debug(" GetCountryCodeByAddr for $_[0]: Already resolved to $res",5); }
	return $res;
	# ----->
}


1;	# Do not remove this line
