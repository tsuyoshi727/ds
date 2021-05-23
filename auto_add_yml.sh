cd ~
git clone https://github.com/tsuyoshi727/ds ./ds
cd ./ds
git checkout sc

ex_list=(`cat ./scripts.md | grep -v "*" | grep jd_`)
# 忽略列表
ig_list=(jd_family jd_delCoupon jd_get_share_code jd_jxnc)
al_list=(${ex_list[*]} ${ig_list[*]})
echo "${al_list[*]}"
grep_list=`echo ${al_list[*]} | awk '{for(i=1;i<=NF;i++) print $i".*"}'`
git checkout jd
non_list=(`cat ./docker/crontab_list.sh | grep "jd" | grep -v "^#" | grep -Ev "$grep_list"`)
echo "$non_list"

# 开始生成新yml文件
[ -z "$non_list" ] && return
sudo cp -rf ./docker/crontab_list.sh ../crontab_list.sh
git checkout main
IFS=$'\n'
for li in ${non_list[*]}
do
  cron=`cat ../crontab_list.sh | grep "$li" | awk -F "node" '{print $1}' | awk '{print $1" "$2" * * *"}'`
  script_name=`cat ../crontab_list.sh | grep "$li" | awk -F " >>" '{print $1}' | awk -F "/" '{print $NF}'| awk -F "." '{print $1}'`
  tmp_list=(`../cat crontab_list.sh | grep -E "#|$li"`)
  for i in `seq 0 ${#tmp_list[*]}`
  do
    if [ "tmp_list[$i]" = "$li" ]; then
      activity_name=tmp_list[$((i-1))]
    fi
  done
  cp -rf ./.github/template/oneByOne.yml "./.github/template/${script_name}.yml"
  sed -i "s/<脚本名>/$script_name/g" "./.github/template/${script_name}.yml"
  sed -i "s/<定时器>/'$cron'/g" "./.github/template/${script_name}.yml"
  sed -i "s/<活动名>/'$cron'/g" "./.github/template/${script_name}.yml"
done
