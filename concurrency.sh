#!/bin/bash
# 多账号并发,不定时
# 变量：要运行的脚本$SCRIPT
# 默认随机延迟5-12秒
set -e
SCRIPT="$1"
DELAY="$2"

cd ~/scripts
echo "DECODE"
encode_str=(`cat ./$1 | grep "window" | awk -F "window" '{print($1)}'| awk -F "var " '{print $(NF-1)}' | awk -F "=" '{print $1}' | sort -u`)
if [ -n "$encode_str" ]; then
    for ec in ${encode_str[*]}
    do
        sed -i "s/return $ec/if($ec.toLowerCase()==\"github\"){$ec=\"GOGOGOGO\"};return $ec/g" ./$1
    done
fi
echo "开始多账号并发"
IFS=$'\n'
if [ -n "$JD_COOKIE" ]; then
  echo "修改cookie"
  sed -i 's/process.env.JD_COOKIE/process.env.JD_COOKIES/g' ./jdCookie.js
  JK_LIST=(`echo "$JD_COOKIE" | awk -F "&" '{for(i=1;i<=NF;i++) print $i}'`)
else
  JK_LIST=(`echo "$JD_COOKIES" | awk -F "&" '{for(i=1;i<=NF;i++) print $i}'`)
fi
num=0
for jk in ${JK_LIST[*]}
do
  cp  -rf ~/scripts ~/scripts${num}
  cd ~/scripts${num}
  sed -i 's/let CookieJDs/let CookieJDss/g' ./jdCookie.js
  sed -i "1i\let CookieJDs = [ '$jk', ]" ./jdCookie.js
  node "./${SCRIPT}" | grep -Ev "pt_pin|pt_key" &
  cd ~
  # 随机延迟5-12秒
  random_time=$(($RANDOM%12+5))
  delay=${DELAY:-$random_time}
  echo "随机延迟${delay}秒"
  sleep ${delay}s
  num=$((num + 1))
done
echo "有账号" "${num}"
unset IFS
wait
