#!/bin/bash
# Author: Albert Astals Cid <aacid@kde.org>
# License: WTFPL 2 - http://sam.zoy.org/wtfpl/

if [ ! -d scripts ]; then
	echo "You have to run the script from the parent directory of scripts/"
	exit
fi

if test "$1" = "--posievepath"; then
	POSIEVEPATH=$2
fi

if test "$3" = "--outputdir"; then
	OUTPUTDIR=$4
fi

if [ -z "$POSIEVEPATH" ]; then
	echo "You have to specify the pology path"
	echo "  Syntax: $0 --posievepath /path/to/posieve --outputdir /path/to/output/dir"
	exit
fi

if [ ! -f "$POSIEVEPATH" ]; then
	echo "$POSIEVEPATH does not exist"
	echo "  Syntax: $0 --pologypath /path/to/posieve --outputdir /path/to/output/dir"
	exit
fi

if [ -z "$OUTPUTDIR" ]; then
	echo "You have to specify the output dir"
	echo "  Syntax: $0 --posievepath /path/to/posieve --outputdir /path/to/output/dir"
	exit
fi

if [ ! -d "$OUTPUTDIR" ]; then
	echo "$OUTPUTDIR is not a directory"
	echo "  Syntax: $0 --pologypath /path/to/posieve --outputdir /path/to/output/dir"
	exit
fi

SVNPATH=http://websvn.kde.org/branches/stable
ORIGSUBDIRSFILE=subdirs
SUBDIRSFILE=subdirs.tmp
REVISION=$(LANG=C svn info | grep "Changed Rev" | cut -d " " -f 4)

# Remove x-test from the teams to process
grep -v "x-test" $ORIGSUBDIRSFILE > $SUBDIRSFILE

# Run posieve
while read it; do
	if [ -d $it/messages/ ]; then
		echo "Running check-xml-kde4 over of $it..."
		$POSIEVEPATH --skip-obsolete check-tp-kde $it/messages/ > $it/xml_message_problems
	else
		rm -f $it/xml_message_problems
		touch $it/xml_message_problems
	fi
	if [ -d $it/docmessages/ ]; then
		echo "Running check-xml-docbook4 over of $it..."
		$POSIEVEPATH --skip-obsolete check-tp-kde $it/docmessages/ > $it/xml_docmessage_problems
	else
		rm -f $it/xml_docmessage_problems
		touch $it/xml_docmessage_problems
	fi
done < $SUBDIRSFILE

# Remove last line from each result file
while read it; do
	head -n-1 $it/xml_message_problems > my_tmp_file
	mv my_tmp_file $it/xml_message_problems
	head -n-1 $it/xml_docmessage_problems > my_tmp_file
	mv my_tmp_file $it/xml_docmessage_problems
done < $SUBDIRSFILE

rm -f my_tmp_file

# create the index.html file
(
cat << HEADDONE
<!DOCTYPE html>
<head>
<title>Errors for revision ${REVISION}</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<link rel="meta" href="http://www.kde.org/labels.rdf" type="application/rdf+xml" title="ICRA labels" />
<meta name="trademark" content="KDE e.V." />
<meta name="description" content="K Desktop Environment Homepage, KDE.org" />
<meta name="MSSmartTagsPreventParsing" content="true" />
<meta name="robots" content="all" />
<meta name="no-email-collection" content="http://www.unspam.com/noemailcollection" />
<link rel="icon" href="/media/images/favicon.ico" /><link rel="shortcut icon" href="/media/images/favicon.ico" />
<link rel="stylesheet" media="screen" type="text/css" title="KDE Colors" href="/media/css.php?mode=normal&amp;css-inc=/" />
<link rel="stylesheet" media="print, embossed" type="text/css" href="/media/css.php?mode=print&amp;css-inc=/" />
<link rel="alternate stylesheet" media="screen, aural, handheld, tty, braille" type="text/css" title="Flat" href="/media/css.php?mode=flat&amp;css-inc=/" />
<link rel="alternate stylesheet" media="screen" type="text/css" title="Browser Colors" href="/media/css.php?color&amp;background&amp;link" />
<link rel="alternate stylesheet" media="screen" type="text/css" title="White on Black" href="/media/css.php?color=%23FFFFFF&amp;background=%23000000&amp;link=%23FF8080" />
<link rel="alternate stylesheet" media="screen" type="text/css" title="Yellow on Blue" href="/media/css.php?color=%23EEEE80&amp;background=%23000060&amp;link=%23FFAA80" />
</head>
<body>
<div id="container">
<div id="header">
  <div id="header_top">
        <div><div>
    <img alt ="" src="/media/images/top-kde.jpg"/>
    KDE Localization
  </div></div></div>
  <div id="header_bottom">
    <div id="location">
      <ul>
	<li><a href="/" accesskey="1">KDE Localization</a></li>
      </ul>
    </div>

    <div id="menu">
<ul><li><a href="/sitemap.php">Sitemap</a></li>
<li><a href="/contact.php">Contact Us</a></li>
</ul>    </div>
  </div>
</div>

    <div id="body_wrapper">
      <div id="body">

<h1>Errors for revision ${REVISION}</h1>
<table class="stats" summary="Statistics">
<tr><th>Language</th><th>Messages</th><th>Docmessages</th></tr>
HEADDONE
) > $OUTPUTDIR/index.html

tmerrors=0
tderrors=0
while read it; do
	merrors=$(wc -l < $it/xml_message_problems)
	derrors=$(wc -l < $it/xml_docmessage_problems)
	((tmerrors = tmerrors + merrors))
	((tderrors = tderrors + derrors))
	teamname=`grep "^$it=" teamnames | cut -d = -f 2`
	echo -n "<tr><td class=\"name\"><img src='/img/flags/$(echo $it | tr '@' '-').png' alt='$teamname flag' class='flag' /> $teamname</td>" >> $OUTPUTDIR/index.html
	if [ $merrors -eq 0 ]; then
		echo -n "<td align=\"right\" style=\"color: gray\">no errors</td>" >> $OUTPUTDIR/index.html
	else
		echo -n "<td align=\"right\"><a href=\"$it/messages.html\">$merrors errors</a></td>" >> $OUTPUTDIR/index.html
	fi
	if [ $derrors -eq 0 ]; then
		echo "<td align=\"right\" style=\"color: gray\">no errors</td></tr>" >> $OUTPUTDIR/index.html
	else
		echo "<td align=\"right\"><a href=\"$it/docmessages.html\">$derrors errors</a></td></tr>" >> $OUTPUTDIR/index.html
	fi
done < $SUBDIRSFILE
echo -n "<tfoot><tr><td><b>Total</b></td>" >> $OUTPUTDIR/index.html
echo -n "<td align=\"right\">$tmerrors errors</td>" >> $OUTPUTDIR/index.html
echo "<td align=\"right\">$tderrors errors</td></tr></tfoot>" >> $OUTPUTDIR/index.html
echo "</div></div></div>" >> $OUTPUTDIR/index.html
echo "</table></body></html>" >> $OUTPUTDIR/index.html

# create the messages.html file
for it in `cat $SUBDIRSFILE`; do
	mkdir -p $OUTPUTDIR/$it
	echo "<html><head><title>$it messages errors for revision $REVISION</title></head><body>" > $OUTPUTDIR/$it/messages.html
	echo "<h1>$it messages errors for revision $REVISION</h1>" >> $OUTPUTDIR/$it/messages.html
	echo "<table>" >> $OUTPUTDIR/$it/messages.html
	echo "<tr><td><b>File</b></td><td><b>Line(#Message number)[info]: Error</b></td><tr>" >> $OUTPUTDIR/$it/messages.html
	exec < $it/xml_message_problems
	while read line
	do
		fileSeparator=`expr index "$line" ":"`
		if [ $fileSeparator != "0" ]; then
			file=${line:0:fileSeparator-1}
			file=`echo $file | sed "s/$it\/messages\///g"`
		
			restofline=${line:fileSeparator}
			restofline=${restofline//&/&amp;}
			restofline=${restofline//</&lt;}
			restofline=${restofline//>/&gt;}
		
			echo -n "<tr><td><a href=\"$SVNPATH/l10n-kde4/$it/messages/$file?revision=$REVISION&view=markup\">$file</a></td>" >> $OUTPUTDIR/$it/messages.html
			echo "<td>$restofline</td></tr>" >> $OUTPUTDIR/$it/messages.html
		fi
	done
	echo "</table>" >> $OUTPUTDIR/$it/messages.html
	echo "<br>" >> $OUTPUTDIR/$it/messages.html
	echo "<br>" >> $OUTPUTDIR/$it/messages.html
	echo "<a href=\"docmessages.html\">$it docmessages errors table</a><br>" >> $OUTPUTDIR/$it/messages.html
	echo "<a href=\"../index.html\">Global errors table</a>" >> $OUTPUTDIR/$it/messages.html
	echo "</body></html>" >> $OUTPUTDIR/$it/messages.html
done

# create the docmessages.html file
for it in `cat $SUBDIRSFILE`; do
	echo "<html><head><title>$it docmessages errors for revision $REVISION</title></head><body>" > $OUTPUTDIR/$it/docmessages.html
	echo "<h1>$it docmessages errors for revision $REVISION</h1>" >> $OUTPUTDIR/$it/docmessages.html
	echo "<table>" >> $OUTPUTDIR/$it/docmessages.html
	echo "<tr><td><b>File</b></td><td><b>Line(#Message number)[info]: Error</b></td><tr>" >> $OUTPUTDIR/$it/docmessages.html
	exec < $it/xml_docmessage_problems
	while read line
	do
		fileSeparator=`expr index "$line" ":"`
		file=${line:0:fileSeparator-1}
		file=`echo $file | sed "s/$it\/docmessages\///g"`
		
		restofline=${line:fileSeparator}
		restofline=${restofline//&/&amp;}
		restofline=${restofline//</&lt;}
		restofline=${restofline//>/&gt;}
		
		echo -n "<tr><td><a href=\"$SVNPATH/l10n-kde4/$it/docmessages/$file?revision=$REVISION&view=markup\">$file</a></td>" >> $OUTPUTDIR/$it/docmessages.html
		echo "<td>$restofline</td></tr>" >> $OUTPUTDIR/$it/docmessages.html
	done
	echo "</table>" >> $OUTPUTDIR/$it/docmessages.html
	echo "<br>" >> $OUTPUTDIR/$it/docmessages.html
	echo "<br>" >> $OUTPUTDIR/$it/docmessages.html
	echo "<a href=\"messages.html\">$it messages errors table</a><br>" >> $OUTPUTDIR/$it/docmessages.html
	echo "<a href=\"../index.html\">Global errors table</a>" >> $OUTPUTDIR/$it/docmessages.html
	echo "</body></html>" >> $OUTPUTDIR/$it/docmessages.html
done

# clean temp files
while read it; do
	rm -f $it/xml_message_problems
	rm -f $it/xml_docmessage_problems
done < $SUBDIRSFILE

rm -f $SUBDIRSFILE

