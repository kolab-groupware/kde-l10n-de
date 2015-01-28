tempfile=`mktemp /tmp/svn.XXXXXX`

copy_dir()
{
  if test ! -d $1 ; then
     svn mkdir $1
     svn pg svn:ignore $stabledir/$1 > $tempfile
     svn ps svn:ignore -F $tempfile $1
  fi
}

stabledir=$1
language=$2
oldrev=$3
newrev=$4

if test -n "$newrev"; then
  svn up -r$newrev "$stabledir/$language/messages"
fi
copy_dir $language
copy_dir $language/messages

modules="kdelibs kdebase kdegames kdesdk kdegraphics kdeutils kdenetwork kdemultimedia kdeadmin kdetoys kdevelop kdepim kdeaddons kdeartwork kdeedu kdeaccessibility kdeplasmoids kdewebdev koffice"

pluralform=`msgcat --no-wrap  $stabledir/$language/messages/kdelibs/kdelibs.po | grep -C 2 "_: Dear transl" | grep ^msgstr | cut -d' ' -f2 | sed -e 's,",,g'`
# http://www.wordforge.org/static/l10n-pluralforms.html
case $pluralform in
    NoPlural)
      ph="Plural-Forms: nplurals=1; plural=0;"
      ;;
    TwoForms)
      ph="Plural-Forms: nplurals=2; plural=n != 1;"
      ;;
    French)
      ph="Plural-Forms: nplurals=2; plural=n>1;"
      ;;
    OneTwoRest)
      ph="Plural-Forms: nplurals=3; plural=n==1 ? 0 : n==2 ? 1 : 2;"
      ;;
    Russian)
      ph="Plural-Forms: nplurals=3; plural=n%100/10==1 ? 2 : n%10==1 ? 0 : (n+9)%10>3 ? 2 : 1;"
      ;;
    Polish)
      ph="Plural-Forms: nplurals=3; plural=n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2;"
      ;;
    Slovenian)
      ph="Plural-Forms: nplurals=4; plural=n%100==1 ? 0 : n%100==2 ? 1 : n%100==3 || n%100==4 ? 2 : 3;"
      ;;
    Lithuanian)
      ph="Plural-Forms: nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && (n%100<10 or n%100>=20) ? 1 : 2);"
      ;;
    Czech|Slovak)
      ph="Plural-Forms: nplurals=3;plural=(n==1) ? 1 : (n>=2 && n<=4) ? 2 : 0;"
      ;;
    Maltese)
      ph="Plural-Forms: nplurals=4; plural=(n==1 ? 0 : n==0 or ( n%100>1 && n%100<11) ? 1 : n%100>10 && n%100<20 ) ? 2 : 3);"
      ;;
    Arabic)
      ph="Plural-Forms: nplurals=4;plural=(n==1) ? 0 : n==2 ? 1 : n < 11 ? 2 : 3;"
      ;;
    Balcan)
      ph="Plural-Forms: nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10< =4 && (n%100<10 or n%100>=20) ? 1 : 2);"
      ;;
    Macedonian)
      ph="Plural-Forms: nplurals=3; plural=n%10==1 ? 0 : n%10==2 ? 1 : 2;"
      ;;
    Gaeilge)
      ph="Plural-Forms: nplurals=5; plural=n==1 ? 0 : n==2 ? 1 : n<7 ? 2 : n < 11 ? 3 : 4";
      ;;
    *)
      echo "No plural form found!"
      exit 1
esac

for mod in $modules; do 
  if test ! -d $stabledir/$language/messages/$mod; then
    continue
  fi
  
  copy_dir $language/messages/$mod

  if test -z "$oldrev"; then
     pos=`cd $stabledir/$language/messages/$mod && find . -name "*.po"`
  else
    pos=`svn log -v -r$oldrev:$newrev $stabledir/$language/messages/$mod | \
       grep /branches/stable/l10n/$language/messages/$mod | \
       sed -e "s,.*messages/$mod/,,"`
  fi
  
  for po in $pos; do
    rm $tempfile
    if test ! -f "templates/messages/$mod/$po"t; then
       continue
    fi
    if test -f $language/messages/$mod/$po; then
        cat $stabledir/$language/messages/$mod/$po > $language/messages/$mod/$po
    else
        svn copy $stabledir/$language/messages/$mod/$po $language/messages/$mod/$po
    fi

    case `basename $po` in
      kickermenu_kate.po|kitchensync.po|libkitchensync.po)
         # only exists for 3.5
         continue
         ;;
      desktop_*)
         msgcat --no-wrap $stabledir/$language/messages/$mod/$po | perl scripts/conversion/kde3_desktop_convert.pl | msgcat - -o $tempfile
         ;;
      *)
         case `basename $po` in
              kontact.po)
                    msggrep -o $language/messages/$mod/$po -v --msgid -e "^Do you really want to delete this note" $language/messages/$mod/$po ; echo $?
                    ;;
              korganizer.po)
	            msggrep -o $language/messages/$mod/$po -v --msgid -e "^1 day" -e "^1 minute" -e "^1 hour" -e "^1 advanced reminder configured" -e "Ne&xt %n Days" -e "^&Next Day" $language/messages/$mod/$po ; echo $?
                    ;;
         esac
         msgcat --no-wrap $language/messages/$mod/$po > $tempfile
         perl scripts/conversion/convert_po.pl "$ph" $tempfile
    esac
    msgmerge -o $language/messages/$mod/$po $tempfile "templates/messages/$mod/$po"t || exit 1
  done
done

if test -f $language/messages/entry.desktop; then
   cat $stabledir/$language/messages/entry.desktop > $language/messages/entry.desktop
else
   svn copy $stabledir/$language/messages/entry.desktop $language/messages/entry.desktop
fi

