#!/bin/bash
# 多账号并发，默认在零点准时触发
# 变量：要运行的脚本$SCRIPT
SCRIPT=$1
timer=${2:-00:00:00}
echo "设置时区"
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

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
num=0
[ "$timer" = "00:00:00" ] && nextdate=`date +%s%N -d "+1 day $timer"` || nextdate=`date +%s%N -d "$timer"`
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
  now=`date +%s%N`
  delay=`echo "scale=3;$((nextdate-now))/1000000000" | bc`
  int_delay=`echo $delay | awk -F "." '{print $1}'`
  (if [ $nextdate -gt $now ];then 
    [ $((int_delay - 0)) -le 3600 ] && echo "未到当天${timer}，等待${delay}秒" && sleep $delay || echo "未到当天${timer}，但超出不远，继续运行"
    node $SCRIPT | grep -Ev "pt_pin|pt_key"
  fi
)&
  cd ~
  num=$((num + 1))
done
unset IFS
wait
