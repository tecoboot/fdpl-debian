#!/bin/bash -e

source fdpl-vars


function main() {
  echo "... Start Update FDPL Debian utility"
  echo "$(date) $SCRIPT started" >>$LOGFILE
  proces_new_branch
  get_branch
  deploy_branch
  echo "... Update FDPL Debian utility completed !!"
  echo "$(date) $SCRIPT ended" >>$LOGFILE
}

function help() {
   echo "Update FDPL Debian utility"
   echo
   echo "Syntax: fdpl-update.sh [-h | -b new-branch]"
   echo "options:"
   echo "h     Show help"
   echo "b     Set & store branch"
   echo
}

while getopts ":hb:" option; do
   case $option in
      h) # display Help
         help
         exit
         ;;
      b) # set new branch
         shift
         NEW_BRANCH=$OPTARG
         ;;
      2) # Restart lb
         restart=true
         ;;
     \?) # Invalid option
         echo "Error: Invalid option"
         help
         exit
         ;;
   esac
done

function proces_new_branch() {
  if [ -n "$NEW_BRANCH" ]; then
    echo "... Branch changed from $BRANCH to $NEW_BRANCH"
    BRANCH=$NEW_BRANCH
    URL=https://github.com/tecoboot/fdpl-debian/archive/refs/heads/$BRANCH.zip
    sed -i "s/BRANCH=.*/BRANCH=$BRANCH/" $FDPL_FOLDER/fdpl-vars
  fi
}

function get_branch() {
  echo "... Get current $BRANCH branch from gitlab"
  wget -q $URL
}

function deploy_branch() {
  echo "... Deploy $BRANCH branch"
  unzip -qq $BRANCH.zip
  rm $BRANCH.zip
  # this action rewrites itself...
  mv fdpl-debian-$BRANCH/* ./
  rmdir fdpl-debian-$BRANCH
}

# go for it
main
exit 0

