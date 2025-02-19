#!/bin/bash -e

source fdpl.vars


function main() {
  echo "... Start FDPL Debian update"
  proces_new_branch
  get_branch
  deploy_branch
  echo "... Update FDPL Debian utility completed !!"
  log_ended_message
}

function help() {
   echo "Update FDPL Debian utility"
   echo
   echo "Syntax: fdpl-update.sh [-b new-branch|f|h]"
   echo "options:"
   echo "b NB  Set & store branch"
   echo "f     Follow log"
   echo "h     Show help"
   echo
}

while getopts ":b:fh" option; do
   case $option in
      b) # set new branch
         shift
         NEW_BRANCH=$OPTARG
         ;;
      f) # Follow
         follow_latest_log
         exit
         ;;
      h) # display Help
         help
         exit
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

