#! /bin/bash
# Copyright: 2015 Sandro Knauß <knauss@kolabsys.com>
# Lincense: same as KDE L10n team (l10n.kde.org) uses
# only a extratcion of l10n scripts update_translations

# updates the pot files for a list of packages

BASE=/work/source/

#git clone github:kolab-groupware/kde-l10n-de.git
L10NBASE=~kdetest/kde/src/l10n

#kde-dev-scripts (git://anongit.kde.org/kde-dev-scripts.git branch KDE/4.14)
KDE_DEV_SCRIPTS=~/src/kde-dev-scripts

postprocess_pot_file()
{
# $1: name of the file to process
  mv $1 $1.orig
  sed -e 's,^"Content-Type: text/plain; charset=CHARSET\\n"$,"Content-Type: text/plain; charset=UTF-8\\n", ; s,"Language-Team: LANGUAGE <LL@li.org>\\n","Language-Team: LANGUAGE <kde-i18n-doc@kde.org>\\n",' < $1.orig > $1
  rm -f $1.orig
}

for mod in kdepimlibs kdepim-runtime kdepim baloo akonadi-ldap-resource zanshin; do
	echo $mod
	cd $BASE/$mod
	( XGETTEXT=`which xgettext` \
          MSGCAT=`which msgcat` \
          EXTRACTRC="extractrc --ignore-no-input" \
          EXTRACTATTR="extractattr" \
          EXTRACT_GRANTLEE_TEMPLATE_STRINGS="$KDE_DEV_SCRIPTS/grantlee_strings_extractor.py" \
          PREPARETIPS="preparetips" \
          REPACKPOT="perl $L10NBASE/scripts/repack-pot.pl" \
          EXTRACT_TR_STRINGS="$L10NBASE/scripts/extract-tr-strings" \
          IGNORE=".git" \
	  podir=$L10NBASE/templates/messages/$mod \
	  $L10NBASE/scripts/extract-messages.sh | tee)
	
	cd $L10NBASE/templates/messages/$mod
	for i in *.pot; do
		if test ! -f $i; then continue; fi
		postprocess_pot_file $i
	done
done

cd $L10NBASE
bash scripts/merge_all.sh
