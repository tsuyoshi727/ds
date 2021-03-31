#!/bin/bash

#set -e
SC_LOG="sharecode.log"
AB_LOG="aboard.log"
LOCATION_LOG="scripts.md"
echo "获得本目录下各脚本位置"
git clone $REPO_URL -b $BRANCH ~/repo
cd ~/repo/.github/workflows

echo "### 活动脚本位置" > ~/$LOCATION_LOG
for file in `ls ./`; do
  Script_list=`cat "$file" | grep -E "jd_.*.js" | awk '{for(i=1;i<=NF;i++) {if($i ~ /.js/) print $i}}' | grep -v "\"" | awk -F ")" '{print $1}' | awk -F "/" '{for(i=1;i<=NF;i++) {if($i ~ /.js/) print $i}}' | awk '!arr[$0]++'`
  if [ -n "$Script_list" ]; then
    echo -e "* $file" >> ~/$LOCATION_LOG
    echo \`\`\` >> ~/$LOCATION_LOG
    echo "$Script_list" >> ~/$LOCATION_LOG
    echo \`\`\` >> ~/$LOCATION_LOG
  fi
done

# 助力码
code_aboard(){
  format_aborad_code="$1 "
  aboard_cipher="$1 "
  satisfy_num=$(($3-0))
  tn=""
  sc_list=(`sed -n '/'码】'.*/'p ${2} | awk -F "】" '{print $2}'`)
  [ $satisfy_num -ne 0 -a ${#sc_list[*]} -ge $satisfy_num ] && echo "该活动循环助力已经可以满足主力要求了" && return
  for i in `seq 0 $((${#sc_list[*]}-1))`
  do
    if [ "$((i/5))"x = "$tn"x ]; then
      format_aborad_code="$format_aborad_code""&${sc_list[$i]}"
    else
      [ -n "$tn" ] && echo "$format_aborad_code" >> ./aboard${tn}
      format_aborad_code="$aboard_cipher""${sc_list[$i]}"
    fi
  tn="$((i/5))"
  done
  echo "$format_aborad_code" >> ./aboard${tn}
}

echo "克隆指定仓库分支"
git clone -b $DESTINATION_BRANCH $REPO_URL ~/ds
cd ~/ds

# 常规turing
code_aboard "/submit_activity_codes jxfactory" "./jd_dreamFactory.log"
code_aboard "/submit_activity_codes pet" "./jd_pet.log" 6
code_aboard "/submit_activity_codes farm" "./jd_fruit.log"
code_aboard "/submit_activity_codes bean" "./jd_plantBean.log"
code_aboard "/submit_activity_codes sgmh" "./jd_sgmh.log"
code_aboard "/submit_activity_codes ddfactory" "./jd_jdfactory.log"
code_aboard "/submit_activity_codes jxcfd" "./jd_cfd.log"
code_aboard "/submit_activity_codes jdglobal" "./jd_global.log"
code_aboard "/submit_activity_codes city" "./jd_city.log"
# commit code
code_aboard "/jdcash" "./jd_cash.log"
code_aboard "/jdzz" "./jd_jdzz.log"
code_aboard "/jdcrazyjoy" "./jd_crazy_joy.log" 7

aborad_file=(`ls | grep aboard`)
for i in `seq 0 $((${#aborad_file[*]}-1))`
do 
  [ "$i"x = "0"x ] && echo "账号"$((i+1)): > aborad.log || echo "账号"$((i+1)): >> aborad.log
  cat ${aborad_file[$i]} >> aborad.log
done
rm -f ${aborad_file[*]}

echo "Resetting origin to: https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
sudo git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"

echo "强制覆盖原文件"
mv -f ~/aborad.log ./$AB_LOG
mv -v ~/$LOCATION_LOG ./$LOCATION_LOG
git config --global user.email "tsuyoshi727@qq.com"
git config --global user.name "tsuyoshi727"
git add .
git commit -m "update `date +%Y%m%d%H%M%S`"

echo "Pushing changings from tmp_upstream to origin"
sudo git push origin "${SOURCE_BRANCH}:${DESTINATION_BRANCH}" --force 
