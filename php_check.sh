#!/bin/bash

###PHP VERSION TO CHECK:
PHPVER=5.3

### Control Panel (UNUSED FOR NOW)
# DirectAdmin: use "DA"
# CPanel:  use "Cpanel"
CP="DA"

### WordPress CLI
# What directory is it in and what did you call it?
# 
WPCLI="/usr/local/bin/wp"

### Check Wordpress
# 1 if you want to check Wordpress
# 0 if you don't.
CHECK_WP=1

### Advanced Wordpress Functions (allows you to update all plugins from script.
# 1 If you want to be able to update WP from the command line

ADV_WP=0


# =============================================================================================
# END OF USER EDITED VARIABLES, YOU SHOULDN'T HAVE TO EDIT ANYTHING BELOW HERE
# =============================================================================================

function print_usage {
        echo "" 
        echo "usage: sudo php_check.sh <USER> <DOMAIN>"
	echo ""
        echo "User:  /home/______ <--- username"
        echo "Domain:   example.com   don't include http:// or a trailing slash at the end."
        echo ""
        exit
}


USER=$1
DOMAIN=$2
if [ `id -u` != "0" ]; then
        sudo -E $0 $1 $2
        exit
fi

if [[ $# -ne 2 ]]; then
	print_usage
fi

if [[ ! -e "/home/$USER" ]]; then
	echo "------ User does not exist!"
	print_usage
fi

if [[ ! -e "/home/$USER/domains/$DOMAIN" ]]; then
	echo "------ Domain does not exist or was mistyped."
	echo "------ Do not include http:// or www. or a trailing slash"
	print_usage
fi

#One of our customers puts Wordpress in a CMS directory.
CMS=0
ORIGDOMAINDIR="/home/$USER/domains/$DOMAIN/public_html"
DOMAINDIR="/home/$USER/domains/$DOMAIN/public_html"

if [[ -e "$DOMAINDIR/cms/wp-config.php" ]]; then
	DOMAINDIR="$DOMAINDIR/cms"
	CMS=1
fi

WP=0
WP_VER=0
WP_PLUGINS=""
if [[ -e "$DOMAINDIR/wp-config.php" ]]; then
	echo "Wordpress detected in $DOMAINDIR"	
	WP=1
fi

if [[ $WP -eq 1 ]]; then
	WP_VER=`sudo -u $USER $WPCLI core version --path="$DOMAINDIR" --skip-themes --skip-plugins`
	if [[ $? -eq 0 ]]; then
		echo ""
		echo "Wordpress Version: $WP_VER"
		echo ""
		echo "Plugin Information:"
		sudo -u $USER $WPCLI plugin list --path="$DOMAINDIR" --skip-themes --skip-plugins
		echo ""
		#WP_PLUGINS=`sudo -u $USER $WPCLI plugin list --path="$DOMAINDIR" --skip-themes --skip-plugins`
		#if [[ $? -eq 0 ]]; then
		#	echo ""
		#	echo "Plugins:"
	#		echo "$WP_PLUGINS"
	#	else
	#		echo "Error determining plugins (If Wordpress is version 3.5 or earlier we can't use this method)"
	#	fi	
	else
		echo "Unable to determine Wordpress Version"
	fi
fi

phptmpver=${PHPVER/./_}
REPORTFILE="PHPcompatibility_${phptmpver}.txt"
echo "Starting PHPCompatibility Check this may take a few moments"
phpcs -p --standard=PHPCompatibility --runtime-set testVersion ${PHPVER} --ignore=*.js,*.css,wp-settings.php,wp-includes/*,wp-admin/* --report-width=240240 --report-file="$ORIGDOMAINDIR/$REPORTFILE" $DOMAINDIR
if [[ $? -eq 0 ]]; then
	echo ""
	echo "No issues found"
	rm $ORIGDOMAINDIR/$REPORTFILE
else
	echo ""
	echo "Compatibility issues found please review the report."
	echo "You can now find the compatibility report at $ORIGDOMAINDIR/$REPORTFILE"
	echo "Or in your browser at http://$DOMAIN/$REPORTFILE"
fi
