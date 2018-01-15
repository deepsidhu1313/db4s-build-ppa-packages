#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

clean(){
  #rm -Rf sqlitebrowser-deb-packaging
  #rm -Rf sqlitebrowser
  rm -Rf build
}

# Define a timestamp function
timestamp() {
  date +"%Y%m%d%H%M"
}

timestamp2() {
  date +"%a, %d %b %Y %H:%M:%S %z"
}


commitCount(){
  #git shortlog | grep -E '^[ ]+\w+' | wc -l
  git rev-list master --count
}



clean #remove existing data
working_dir="$(pwd)"
majorversion="3.10.100ubuntu1-0"
declare -a  distros=("xenial" "zesty" "artful" "bionic") # distributions codenames
if [ -d "${working_dir}/sqlitebrowser-deb-packaging" ]
then
  echo "deb packing git repo found under ${working_dir}/sqlitebrowser-deb-packaging"
  cd "${working_dir}/sqlitebrowser-deb-packaging"
  echo "pulling latest code"
  git pull
else
  echo "Warning! deb packing git repo not found under ${working_dir}/sqlitebrowser-deb-packaging"
  echo "Info! cloning https://github.com/deepsidhu1313/sqlitebrowser-deb-packaging.git to ${working_dir}/sqlitebrowser-deb-packaging"
  git clone https://github.com/deepsidhu1313/sqlitebrowser-deb-packaging.git
fi
cd "${working_dir}"
if [ -d "${working_dir}/sqlitebrowser" ]
then
  echo "sqlitebrowser git repo found under ${working_dir}/sqlitebrowser"
  cd "${working_dir}/sqlitebrowser"
  echo "pulling latest code"
  git clean -dffx #as suggested by @justinclift
  git pull
else
  echo "Warning! DB4S git repo not found under ${working_dir}/sqlitebrowser"
  echo "Info! cloning https://github.com/sqlitebrowser/sqlitebrowser.git to ${working_dir}/sqlitebrowser"
  git clone https://github.com/sqlitebrowser/sqlitebrowser.git
fi
if [ ! -f "${working_dir}/lastrevno" ]; then
  echo "Last Revision number on master branch not found! Considering 0 for start"
  echo '0' > "${working_dir}/lastrevno"
fi
cd "${working_dir}/sqlitebrowser"
commitCount > "${working_dir}/revno"
pathtolastrevno="${working_dir}/lastrevno"
pathtorevno="${working_dir}/revno"
lastrevno=$(cat "$pathtolastrevno")
revno=$(cat "$pathtorevno")
version0="${revno}~"
version=$version0$(timestamp)
if [[ "${revno}" -gt "${lastrevno}" ]]; then
  echo "Code changed Latest Revision number on master branch is $revno"

  for i in "${distros[@]}"
  do
    cd "${working_dir}/"
    mkdir -p "${working_dir}/build/$i/sqlitebrowser/"
    rsync -aAX sqlitebrowser-deb-packaging/ "build/$i/sqlitebrowser/" --exclude='.git'
    rsync -aAX sqlitebrowser/ "build/$i/sqlitebrowser/" --exclude='.git'
    cd "${working_dir}/build/$i/sqlitebrowser/"
    echo "sqlitebrowser ($majorversion~${version}~$i) $i; urgency=high

  * Nightly Build

 -- Gajj Linux <linuxgndu@gmail.com>  $(timestamp2)

    " > "${working_dir}/build/$i/sqlitebrowser/debian/changelog.temp"
    cat "${working_dir}/build/$i/sqlitebrowser/debian/changelog" >> "${working_dir}/build/$i/sqlitebrowser/debian/changelog.temp"
    rm "${working_dir}/build/$i/sqlitebrowser/debian/changelog"
    mv "${working_dir}/build/$i/sqlitebrowser/debian/changelog.temp" "${working_dir}/build/$i/sqlitebrowser/debian/changelog"
    cd "${working_dir}/build/$i/sqlitebrowser/"
    expect "${working_dir}/debuild.xp" # build packages using expect script which is set to send passwords on prompt to debuild process
    cd "${working_dir}/build/$i/"
    # upload packages to ppa
    dput ppa:linuxgndu/sqlitebrowser-testing sqlitebrowser_*source.changes

    cd "${working_dir}"

  done
  # change last revision number
  echo "${revno}" > "${working_dir}/lastrevno"
fi
