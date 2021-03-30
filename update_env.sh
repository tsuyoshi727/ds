#!/usr/bin/env sh
echo "设置时区"
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo "拉取源码"
git clone --depth 1 -b jd https://github.com/tracefish/ds.git ~/scripts
# git checkout jd
cd  ~/scripts
echo "修改源码"
sed -i "s/indexOf('GITHUB')/indexOf('GOGOGOGO')/g" `ls -l |grep -v ^d|awk '{print $9}'`
sed -i 's/indexOf("GITHUB")/indexOf("GOGOGOGO")/g' `ls -l |grep -v ^d|awk '{print $9}'`
# echo "修改文件"
# git clone -b sc https://github.com/tracefish/ds.git ./sharecode
# sed -i '2i\process.env.SHARE_CODE_FILE = ".\/sharecode\/sharecode.log";' ./utils/jdShareCodes.js
# echo "修改助力码"
# SGMH_SHARECODES=(`cat ~/sharecode.log | while read LINE; do echo $LINE; done | grep "闪购盲盒"| awk -F "】" '{printf $2"@"}'`)
npm install
[ -e "run_scripts.sh" ] && chmod 755 run_scripts.sh
