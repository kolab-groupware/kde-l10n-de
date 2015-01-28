oldrev=`svn pg last_update .`
newrev=`svn info svn+ssh://svn.kde.org/home/kde | grep Revision | cut -d' ' -f2`
svn up -r$newrev .
svn up -r$newrev ~/prod/kde-i18n/subdirs
for lang in `cat subdirs`; do
  echo $lang
  sh ./scripts/conversion/convert_language.sh ~/prod/kde-i18n/ $lang $oldrev $newrev
done
svn ps last_update $newrev .
svn ci 
