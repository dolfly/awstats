# AWSTATS WORMS DATABASE
#-------------------------------------------------------
# If you want to add worms to extend AWStats database detection capabilities,
# you must add an entry in WormsSearchIDOrder, WormsHashID and WormsHashLib.
#-------------------------------------------------------
# $Revision: 1.1 $ - $Author: eldy $ - $Date: 2002-07-11 21:37:41 $


#package AWSWORMS;



# WormsSearchIDOrder
# This list is used to know in which order to search Robot IDs.
# This array is array of Worms matching criteria found in URL submitted
# to web server.
#-------------------------------------------------------
@WormsSearchIDOrder = (
"root.exe?/c",
"cmd.exe?/c"
);


# WormsHashID
# Each Worms search ID is associated to a string that is unique name of worm.
#--------------------------------------------------------------------------
%WormsHashID	= (
"root.exe?/c","xxx","cmd.exe?/c","xxx"
);


# WormsHashLib
# Worms name list ("worm unique id in lower case","worm clear text")
# Each unique ID string is associated to a label
#-------------------------------------------------------
%WormsHashLib   = (
"xxx","xxx worm",
);


1;
