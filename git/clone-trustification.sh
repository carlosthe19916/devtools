mkdir -p ~/git/trustification/
cd ~/git/trustification/

for i in trustification.github.io trustification trustify trustify-api-tests trustify-ui trustify-ui-tests trustify-operator trustify-helm-charts trustify-ci release-tools
do
  git clone git@github.com:carlosthe19916/$i.git
  cd $i
  git remote add upstream git@github.com:trustification/$i.git
  cd ..
done
