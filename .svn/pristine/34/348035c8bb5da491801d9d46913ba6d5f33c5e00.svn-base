CDPATH=
# requires find, sed, revpath, egrep, grep, fgrep, cat, rm, basename

if ! which revpath >/dev/null 2>/dev/null; then
  echo "!!! Cannot find revpath: this script may fail" >&2
  echo "!!! Try installing the imake package" >&2
fi

add_cmake_files_manpage() {
  local dir_local=$1;
  for manfile in `find $dir_local/ -name man-*.docbook`; do
    subdir=$(dirname $manfile)
    fname=$(basename $manfile)
    name=${fname%.docbook}
    no=${name##*.}
    echo "kde4_create_manpage($fname $no INSTALL_DESTINATION \${MAN_INSTALL_DIR}/\${CURRENT_LANG}/ )" >> $subdir/CMakeLists.txt
  done
}

add_cmake_files_doc() {
  local dir_local=$1;
  local list_dir;
  # This is just not to make a find * in a dir that has no items and so we avoid getting a find warning
  count=`cd $dir_local && find . -mindepth 1 -maxdepth 1 -regex '.*' | egrep -v "\.svn" | wc -l`
  if [ $count -eq 0 ]; then
      return
  fi
  list_dir=`cd $dir_local && find * -maxdepth 0 -type d -not -empty | grep -v "\.svn"`;
  # remove old CMakeLists.txt
  rm -f $dir_local/CMakeLists.txt;
  for subdir in $list_dir; do
      echo "add_subdirectory( $subdir )" >> $dir_local/CMakeLists.txt
      if test -f $dir_local/index.docbook; then
          if ! grep -q "kde4_create_handbook" $dir_local/CMakeLists.txt; then
              echo "kde4_create_handbook(index.docbook INSTALL_DESTINATION \${HTML_INSTALL_DIR}/\${CURRENT_LANG}/ )" >> $dir_local/CMakeLists.txt;
          fi
      fi
      add_cmake_files_doc $dir_local/$subdir;
      case $subdir in
           common)
               echo "FILE(GLOB _html *.html)" >> $dir_local/$subdir/CMakeLists.txt;
               echo "FILE(GLOB _css *.css)" >> $dir_local/$subdir/CMakeLists.txt;
               echo "FILE(GLOB _pngs *.png)" >> $dir_local/$subdir/CMakeLists.txt;
               echo "install( FILES \${_html} \${_css} \${_png} DESTINATION \${HTML_INSTALL_DIR}/\${CURRENT_LANG}/common)" >> $dir_local/$subdir/CMakeLists.txt;
               #howto install the missing symlinks e.g. ${HTML_INSTALL_DIR}/en/common/1.png  ${HTML_INSTALL_DIR}/\${CURRENT_LANG}/common/1.png ?
               ;;
           *)
               if test -f $dir_local/$subdir/index.docbook; then
                   # test if it's a kcontrol module.
                   local kcontrol_found=`echo $dir_local/$subdir | grep kcontrol`;
                   local add_subdir=;
                   if [  ! -z $kcontrol_found ]; then
                        add_subdir="SUBDIR kcontrol/$subdir";
                   fi
                   local kioslave_found=`echo $dir_local/$subdir | grep kioslave`;
                   if [  ! -z $kioslave_found ]; then 
                        add_subdir="SUBDIR kioslave/$subdir";  
                   fi
                   # test if it's a khelpcenter module (glossary, documentationnotfound)
                   local glossary_found=`echo $dir_local/$subdir | grep glossary`;
                   if [  ! -z $glossary_found ]; then 
                        add_subdir="SUBDIR khelpcenter/$subdir";
                   fi
                   local documentationnotfound_found=`echo $dir_local/$subdir | grep documentationnotfound`;
                   if [  ! -z $documentationnotfound_found ]; then 
                        add_subdir="SUBDIR khelpcenter/$subdir";
                   fi
                   echo "kde4_create_handbook(index.docbook INSTALL_DESTINATION \${HTML_INSTALL_DIR}/\${CURRENT_LANG}/ $add_subdir )" >> $dir_local/$subdir/CMakeLists.txt;
               fi
               ;;
      esac
  done
}

subdirs="$@"
if test -z "$subdirs"; then
    if test -f inst-apps; then
	    subdirs=`cat inst-apps`
    else
	    subdirs=`cat subdirs`
    fi
fi

for dir in $subdirs; do 
    echo "processing $dir"
    # Top-level language project setup.
    : > $dir/CMakeLists.txt
    if test ! -f CMakeLists.txt; then # not in sub-language dir
        cat > $dir/CMakeLists.txt <<EOF
project(kde-i18n-$dir)

# Search KDE installation
find_package(KDE4 REQUIRED)
find_package(Gettext REQUIRED)
include (KDE4Defaults)
include(MacroOptionalAddSubdirectory)

if (NOT GETTEXT_MSGMERGE_EXECUTABLE)
   MESSAGE(FATAL_ERROR "Please install the msgmerge binary")
endif (NOT GETTEXT_MSGMERGE_EXECUTABLE)

IF(NOT GETTEXT_MSGFMT_EXECUTABLE)
   MESSAGE(FATAL_ERROR "Please install the msgfmt binary")
endif (NOT GETTEXT_MSGFMT_EXECUTABLE)

EOF
    fi
    echo "set(CURRENT_LANG $dir)" >> $dir/CMakeLists.txt
    echo "" >> $dir/CMakeLists.txt

    # UI message catalogs.
        if test -d $dir/messages; then
            echo "macro_optional_add_subdirectory( messages )" >> $dir/CMakeLists.txt 

  	    : > $dir/messages/CMakeLists.txt
	    dirs=`cd $dir/messages && find * -maxdepth 1 -type d -not -empty | fgrep -v others | fgrep -v www.kde.org | fgrep -v "\.svn" | grep -v ^www$ | grep -v koffice`
	    for dir2 in $dirs; do
               echo "file(GLOB _po_files *.po)" > $dir/messages/$dir2/CMakeLists.txt
               echo "GETTEXT_PROCESS_PO_FILES(\${CURRENT_LANG} ALL INSTALL_DESTINATION \${LOCALE_INSTALL_DIR} \${_po_files} )" >> $dir/messages/$dir2/CMakeLists.txt
	       echo "add_subdirectory($dir2)" >> $dir/messages/CMakeLists.txt
	    done
	    files=`cd $dir/messages && find -L . -maxdepth 1 -type f | egrep -v "CMakeLists.txt|no-auto-merge" | sed -e "s,^./,,"`
	    for file in $files; do
		echo "install(FILES $file DESTINATION \${LOCALE_INSTALL_DIR}/\${CURRENT_LANG}/ )" >> $dir/messages/CMakeLists.txt
	    done
        fi

    # Documentation.
	dirs=
	if test -d $dir/docs; then
           echo "macro_optional_add_subdirectory( docs )" >> $dir/CMakeLists.txt;
           add_cmake_files_doc  $dir/docs; 
           add_cmake_files_manpage $dir/docs;
	fi

	#for dir2 in $dirs; do
	#   if test ! -f $dir2/Makefile.am; then
	#        echo "KDE_LANG = $dir" > $dir2/Makefile.am
	#	echo 'SUBDIRS = $(AUTODIRS)' >> $dir2/Makefile.am
	#	subdir=AUTO
	#	case "$dir2/Makefile.am" in
	#		$dir/docs/kdebase/*/Makefile.am) \
	#			subdir=`echo $dir2 | sed -e "s#.*docs/[^/]*/##; s#/Makefile.am##"`
	#			case $subdir in
	#				visualdict|faq|userguide|quickstart|glossary)
	#					subdir=khelpcenter/$subdir
	#					;;
	#			esac
	#			;;
	#		$dir/docs/kdesdk/scripts/*/Makefile.am)
	#			subdir=`echo $dir2 | sed -e "s#.*docs/[^/]*/##; s#/Makefile.am##; s#scripts/##"`
	#			;;
	#		$dir/docs/*/*/*/Makefile.am)
	#			subdir=`echo $dir2 | sed -e "s#.*docs/[^/]*/##; s#/Makefile.am##"`
	#			;;
	#	esac
	#	echo "KDE_DOCS = $subdir" >> $dir2/Makefile.am
	#	echo "KDE_MANS = AUTO" >> $dir2/Makefile.am
	#   fi
	#done

    # Custom localized application data.
    if test -d $dir/data; then
        # remove old CMakeLists.txt
        rm -f $dir/data/CMakeLists.txt;
        echo "macro_optional_add_subdirectory( data )" >> $dir/CMakeLists.txt
        dirs=`cd $dir/data && find * -maxdepth 0 -type d -not -empty | fgrep -v .svn`
        for dir2 in $dirs; do
            echo "add_subdirectory($dir2)" >> $dir/data/CMakeLists.txt
            rm -f $dir/data/$dir2/CMakeLists.txt;
            subdirs=`cd $dir/data/$dir2 && find * -maxdepth 0 -type d -not -empty | fgrep -v .svn`
            for subdir2 in $subdirs; do
                echo "add_subdirectory($subdir2)" >> $dir/data/$dir2/CMakeLists.txt
            done
        done
    fi

    # Transcript files.
    if test -d $dir/scripts; then
        echo "macro_optional_add_subdirectory( scripts )" >> $dir/CMakeLists.txt
        dirs2=`cd $dir/scripts && find * -maxdepth 0 -type d -not -empty | fgrep -v .svn | fgrep -v internal`
        : > $dir/scripts/CMakeLists.txt
        cmakeincfile=CMakeInclude.cmake
        if test -f $dir/scripts/$cmakeincfile; then
            echo "include($cmakeincfile)" >> $dir/scripts/CMakeLists.txt
        fi
        for dir2 in $dirs2; do
            echo "add_subdirectory($dir2)" >> $dir/scripts/CMakeLists.txt
            tsdirs=`cd $dir/scripts/$dir2 && find * -maxdepth 0 -type d -not -empty | fgrep -v .svn | fgrep -v internal`
            : > $dir/scripts/$dir2/CMakeLists.txt
            for tsdir in $tsdirs; do
                echo "kde4_install_ts_files(\${CURRENT_LANG} $tsdir)" >> $dir/scripts/$dir2/CMakeLists.txt
            done
        done
    fi

    # Add subdirs of sub-languages.
    sublangs=`find $dir -maxdepth 1 -type d -iname "$dir[_@]*" -not -empty`
    for subl in $sublangs; do
        sublc=`basename $subl`
        echo "macro_optional_add_subdirectory( $sublc )" >> $dir/CMakeLists.txt
    done
    # Recurse for sub-languages.
    agcmd=`echo $0`
    if [ `echo $0 | cut -b 1` != '/' ]; then
      revp=`revpath $dir`
      agcmd=`echo $0 | sed "s:^\([^/]\):$revp\0:"` # change autogen.sh path if relative
    fi
    cd $dir
    for subl in $sublangs; do
        $agcmd `basename $subl`
    done
    cd ..
done
