#!/usr/bin/env sh

set -e

mkdir -p ~/jd_scripts/
git clone https://gitee.com/twinzo/scripts/ ~/jd_scripts
cd ~/jd_scripts/

echo "git 回退"
git reset --hard 67d87e487b89dc0f060c0cf9bc2523a4e95cab98

cd ~/jd_scripts
#UPSTREAM_REPO=`git remote -v | grep origin | grep fetch | awk '{print $2}'`
git remote --verbose

echo "Resetting origin to: https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
sudo git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
git remote --verbose

echo "Pushing changings from tmp_upstream to origin"
sudo git push origin "67d87e487b89dc0f060c0cf9bc2523a4e95cab98:refs/heads/${DESTINATION_BRANCH}" --force

git remote --verbose
