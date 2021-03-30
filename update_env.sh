#!/usr/bin/env sh
echo "设置时区"
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

git checkout -b jd

echo "拉取源码"
#git clone --depth 1 -b jd https://github.com/tracefish/ds.git ~/scripts
mkdir ~/scripts
cp -rf ./* cd  ~/scripts
cd  ~/scripts
echo "修改源码"
sed -i "s/indexOf('GITHUB')/indexOf('GOGOGOGO')/g" `ls -l |grep -v ^d|awk '{print $9}'`
sed -i 's/indexOf("GITHUB")/indexOf("GOGOGOGO")/g' `ls -l |grep -v ^d|awk '{print $9}'`
npm install

cd ..
[ -e "run_scripts.sh" ] && chmod 755 run_scripts.sh
