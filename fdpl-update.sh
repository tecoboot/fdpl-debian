#!/bin/bash -e

source fdpl-vars

echo "... Get current $BRANCH branch from gitlab"
wget -q $URL

echo "... Deploy $BRANCH branch"
unzip -qq $BRANCH.zip 
rm $BRANCH.zip
# this action rewrites itself...
mv fdpl-debian-$BRANCH/* ./
rmdir fdpl-debian-$BRANCH

exit 0
