#!/usr/bin/perl
#-----------------------------------------------------------------------------
# HashFiles AWStats plugin
# Allows AWStats to read/save its data file as native hash files.
# This increase read andwrite files operations.
#-----------------------------------------------------------------------------
# Perl Required Modules: Storable
#-----------------------------------------------------------------------------
# $Revision: 1.1 $ - $Author: eldy $ - $Date: 2002-07-22 18:50:45 $

use Storable;


$PluginHiRes=1;

1;	# Do not remove this line
