#!/usr/bin/perl
#-----------------------------------------------------------------------------
# TimeHires AWStats plugin
# Change time accuracy in showsteps option from seconds to milliseconds
#-----------------------------------------------------------------------------
# Perl Required Modules: Time::HiRes
#-----------------------------------------------------------------------------
# $Revision: 1.2 $ - $Author: eldy $ - $Date: 2002-07-22 18:04:42 $

use Time::HiRes qw( gettimeofday );


$PluginTimeHiRes=1;

1;	# Do not remove this line
