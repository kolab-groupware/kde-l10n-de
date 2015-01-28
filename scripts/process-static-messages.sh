#! /bin/bash

podir=${podir:-$PWD/po}
files=`find . -name StaticMessages.sh`
dirs=`for i in $files; do echo \`dirname $i\`; done | sort -u`
tmpname="$PWD/messages.log"
EXTRACTRC=${EXTRACTRC:-extractrc}
EXTRACTATTR=${EXTRACTATTR:-extractattr}
EXTRACT_GRANTLEE_TEMPLATE_STRINGS=${EXTRACT_GRANTLEE_TEMPLATE_STRINGS:-grantlee_strings_extractor.py}
MSGCAT=${MSGCAT:-msgcat}
PREPARETIPS=${PREPARETIPS:-preparetips}
REPACKPOT=${REPACKPOT:-repack-pot.pl}
export EXTRACTRC EXTRACTATTR MSGCAT PREPARETIPS REPACKPOT EXTRACT_GRANTLEE_TEMPLATE_STRINGS
if [ "x$IGNORE" = "x" ]; then
    IGNORE="/tests/"
else
    IGNORE="$IGNORE
/tests/"
fi

for subdir in $dirs; do
    test -z "$VERBOSE" || echo "Making static messages export in $subdir"
    (cd $subdir

    if test -f StaticMessages.sh; then
        if find . -name \*.c\* -o -name \*.h\* | fgrep -v "$IGNORE" | xargs fgrep -s -q KAboutData ; then
            echo 'i18nc("NAME OF TRANSLATORS","Your names");' >> rc.cpp
            echo 'i18nc("EMAIL OF TRANSLATORS","Your emails");' >> rc.cpp
        fi
        
        XGETTEXT_FLAGS_QT="--from-code=UTF-8 -C --qt -ktr:1,1t -ktr:1,2c,2t -kQT_TRANSLATE_NOOP:1c,2,2t -kQT_TR_NOOP:1,1t -ktranslate:1c,2,2t -ktranslate:2,3c,3t"
        XGETTEXT_FLAGS="--copyright-holder=This_file_is_part_of_KDE --from-code=UTF-8 -C --kde -ci18n -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 -ktr2i18n:1 -kI18N_NOOP:1 -kI18N_NOOP2:1c,2 -kI18N_NOOP2_NOSTRIP:1c,2 -kaliasLocale -kki18n:1 -kki18nc:1c,2 -kki18np:1,2 -kki18ncp:1c,2,3 --msgid-bugs-address=http://bugs.kde.org"
        XGETTEXT_FLAGS_WWW="--copyright-holder=This_file_is_part_of_KDE --from-code=UTF-8 -L PHP -ki18n -ki18n_var -ki18n_noop --msgid-bugs-address=http://bugs.kde.org"
        export XGETTEXT_FLAGS
        export XGETTEXT_FLAGS_QT
        export XGETTEXT_FLAGS_WWW
        
        # FILENAME and export_pot_file come from StaticMessages.sh
        source StaticMessages.sh
        if test -n "$FILENAME"; then
            export_pot_file $podir/$FILENAME.pot
        else
            echo "StaticMessages.sh in $subdir doesn't define FILENAME"
        fi
        FILENAME=""
    else
       echo "StaticMessages.sh in $subdir existed seconds ago. This is weird"
    fi
    exit_code=$?
    if test "$exit_code" -ne 0; then
        echo "Bash exit code: $exit_code"
    fi
    ) >& $tmpname
    test -s $tmpname && { echo $subdir ; cat "$tmpname"; }
    
    
    
    
    test -z "$VERBOSE" || echo "Making static messages import in $subdir"
    (cd $subdir

    if test -n "$BASEDIR"; then
        if test -n "$transmod"; then
            if test -n "$templatename"; then
                if test -f StaticMessages.sh; then
                    # FILENAME and import_po_files come from StaticMessages.sh
                    source StaticMessages.sh
                    if test -n "$FILENAME"; then
                        # Import the po files
                        temppodir=`mktemp -d`
                        for language in `ls $BASEDIR/$transmod`; do
                            file=$BASEDIR/$transmod/$language/messages/$templatename/$FILENAME.po
                            if [ ! -e $file ]; then
                                continue
                            fi

                            cp $file $temppodir/$language.po
                        done
                        rm -f $temppodir/x-test.po

                        import_po_files $temppodir
                    else
                        echo "StaticMessages.sh in $subdir doesn't define FILENAME"
                    fi
                    FILENAME=""
                    rm -rf $temppodir
                else
                    echo "StaticMessages.sh in $subdir existed seconds ago. This is weird"
                fi
            else
                echo "templatename not defined, can't run the import step"
            fi
        else
            echo "transmod not defined, can't run the import step"
        fi
    else
        echo "BASEDIR not defined, can't run the import step"
    fi
    exit_code=$?
    if test "$exit_code" -ne 0; then
        echo "Bash exit code: $exit_code"
    fi
    ) >& $tmpname
    test -s $tmpname && { echo $subdir ; cat "$tmpname"; }
done

# Repack extracted templates.
find -L $podir -iname '*.pot' | xargs -r -n1 $REPACKPOT

rm -f $tmpname
