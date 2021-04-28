#!/bin/bash
# 多账号并发,不定时
# 变量：要运行的脚本$SCRIPT
# 默认随机延迟5-12秒
# DD_BOT_SECRET_SPEC：特别推送
# DD_BOT_TOKEN_SPEC：特别推送
# 通过 `test.sh jd.js delay 2` 指定延迟时间
# `test.sh jd.js 00:00:12 2` 通过时间，指定脚本 运行时间 和 延迟时间（默认为0）
# `test.sh jd.js 12 2` 通过分钟（小于等于十分钟，需要设置定时在上一个小时触发），指定脚本 运行时间 和 延迟时间（默认为0）
# 版本：v2.82

# set -e
SCRIPT="$1"
SKD="$2"
# 延迟时间设置
DELAY="$3"

SCRIPT_NAME=`echo "${1}" | awk -F "." '{print $1}'`
LOG="${SCRIPT_NAME}.log"
NOTIFY_CONF="dt.conf"
REPO_URL="https://github.com/tsuyoshi727/ds"
REPO_BRANCH="sc"
# 防止action抽风，加双引号不能输出home目录
home=`echo ~`
# 助力码文件目录
SHCD_DIR="${home}/ds"
# 脚本文件初始目录
SCRIPT_DIR="${home}/scripts"

[ ! -d ${SHCD_DIR} ] && git clone -b "$REPO_BRANCH" $REPO_URL ${SHCD_DIR}

# 准点触发
act_by_min(){
    min=${1}
    if [ ! -n `echo $min | grep ":"` ]; then
	hour=`date +%H`
	if [ $min -le 10 ]; then
		hour=$((hour + 1))
		[ "$hour" = "24" ] && hour="00"
	fi
	timer="${hour}:${min}:00"
    fi
    [ "$timer" = "00:00:00" ] && nextdate=`date +%s%N -d "+1 day $timer"` || nextdate=`date +%s%N -d "$timer"`
    echo $nextdate
}

# 修改文件
modify_scripts(){
	cd ${SCRIPT_DIR}

	if [ -n "$SYNCURL" ]; then
    	echo "下载脚本"
	curl "$SYNCURL" > ./${SCRIPT}
    	# 外链脚本替换
	sed -i "s/indexOf('GITHUB')/indexOf('GOGOGOGO')/g" `ls -l | grep -v ^d | awk '{print $9}'`
    	sed -i 's/indexOf("GITHUB")/indexOf("GOGOGOGO")/g' `ls -l | grep -v ^d | awk '{print $9}'`
	fi
	[ ! -e "./$SCRIPT" ] && echo "脚本不存在" && exit 0
	
	echo "修改发送方式"
	if [ -n "$DD_BOT_TOKEN_SPEC" -a -n "$DD_BOT_SECRET_SPEC" ]; then
	    cp -f ./sendNotify.js ./sendNotify_diy.js
	    sed -i "s/desp += author/\/\/desp += author/g" ./sendNotify.js
	    sed -i "/text = text.match/a   var fs = require('fs');fs.appendFile(\"./\" + \"${NOTIFY_CONF}name\", text + \"\\\n\", function(err) {if(err) {return console.log(err);}});fs.appendFile(\"./\" + \"${NOTIFY_CONF}\", desp + \"\\\n\", function(err) {if(err) {return console.log(err);}});\n  return" ./sendNotify.js
	fi
	echo "DECODE"
	encode_str=(`cat ./${SCRIPT} | grep "window" | awk -F "window" '{print($1)}'| awk -F "var " '{print $(NF-1)}' | awk -F "=" '{print $1}' | sort -u`)
	if [ -n "$encode_str" ]; then
	    for ed in ${encode_str[*]}
	    do
	        sed -i "s/return $ed/if($ed.toLowerCase()==\"github\"){$ed=\"GOGOGOGO\"};return $ed/g" ./${SCRIPT}
	    done
	fi
}

# 格式化助力码到文本
format_sc2txt(){
# $1 助力码文件
# $2 助力码文本生成位置
    sc_file=$1
    fsr_file=$2
    #${SCRIPT_NAME}.conf
    [ ! -e "$sc_file" ] && return 0
    sc_list=(`cat "$sc_file" | while read LINE; do echo $LINE; done | awk -F "】" '{print $2}'`)
    for e in `seq 1 ${#sc_list[*]}`
    do 
        sc_list+=(${sc_list[0]})
        unset sc_list[0]
        sc_list=(${sc_list[*]})
        if [ $e -eq 1 ]; then
            echo ${sc_list[*]:0}| awk '{for(i=1;i<=NF;i++) {if(i==NF) print $i;else printf $i"@"}}' > $fsr_file
        else
            echo ${sc_list[*]:0} | awk '{for(i=1;i<=NF;i++) {if(i==NF) print $i;else printf $i"@"}}' >> $fsr_file
        fi
    done
    if [ -n `echo "$JD_COOKIE" | grep "&"` ]; then
	JK_LIST=(`echo "$JD_COOKIE" | awk -F "&" '{for(i=1;i<=NF;i++) print $i}'`)
    else
	JK_LIST=(`echo "$JD_COOKIE" | awk -F "$" '{for(i=1;i<=NF;i++){{if(length($i)!=0) print $i}}'`)
    fi
    if [ -n "$JK_LIST" ]; then
        diff=$((${#JK_LIST[*]}-${#sc_list[*]}))
        for e in `seq 1 $diff`
        do 
            sc_list+=(${sc_list[0]})
            unset sc_list[0]
            sc_list=(${sc_list[*]})
            echo ${sc_list[*]:0} | awk '{for(i=1;i<=NF;i++) {if(i==NF) print $i;else printf $i"@"}}' >> $fsr_file
        done
    fi
}

# 添加助力码
autoHelp(){
# $1 脚本文件
# $2 助力码文件所在
# $3 cookie顺序
    sr_file=$1
    sc_file=$2
    jk_ordr=$3
    f_shcode=""
    
    [ ! -e "$sc_file" -a -z "$MY_SHARECODES" ] && return 0
    f_shcode="$f_shcode""'""`cat $sc_file | head -n $jk_ordr | tail -n 1`""',""\n"
    [ -n "$MY_SHARECODES" ] && f_shcode="$f_shcode""'$MY_SHARECODES',\n"
    sed -i "s/let shareCodes = \[/let shareCodes = \[\n${f_shcode}/g" "./$sr_file"
    sed -i "s/const inviteCodes = \[/const inviteCodes = \[\n${f_shcode}/g" "./$sr_file"
    sed -i "s/let inviteCodes = \[/let inviteCodes = \[\n${f_shcode}/g" "./$sr_file"
    # 修改种豆得豆
    if [ "$1" = "jd_plantBean.js" ]; then
        sed -i "s/let PlantBeanShareCodes = \[/let PlantBeanShareCodes = \[\n${f_shcode}/g" "./jdPlantBeanShareCodes.js"
    fi
    # 修改东东萌宠
    if [ "$1" = "jd_pet.js" ]; then
        sed -i "s/let PetShareCodes = \[/let PetShareCodes = \[\n${f_shcode}/g" "./jdPetShareCodes.js"
    fi
    # 修改东东农场
    if [ "$1" = "jd_fruit.js" ]; then
        sed -i "s/let FruitShareCodes = \[/let FruitShareCodes = \[\n${f_shcode}/g" "./jdFruitShareCodes.js"
    fi
    # 修改京喜工厂
    if [ "$1" = "jd_dreamFactory.js" ]; then
        sed -i "s/let shareCodes = \[/let shareCodes = \[\n${f_shcode}/g" "./jdDreamFactoryShareCodes.js"
    fi
    # 修改东东工厂
    if [ "$1" = "jd_jdfactory.js" ]; then
        sed -i "s/let shareCodes = \[/let shareCodes = \[\n${f_shcode}/g" "./jdFactoryShareCodes.js"
    fi
}

# 收集助力码
collectSharecode(){
    echo "${1}：收集新助力码"
    code=`sed -n '/'码】'.*/'p ${1} | grep -v "提交"`
    if [ -z "$code" ]; then
        activity=`sed -n '/配置文件.*/'p "./${LOG}" | awk -F "获取" '{print $2}' | awk -F "配置" '{print $1}'`
        name=(`sed -n '/'【京东账号'.*/'p "./${LOG}" | grep "开始" | awk -F "开始" '{print $2}' |sed 's/】/（/g'| awk -v ac="$activity" -F "*" '{print $1"）" ac "好友助力码】"}'`)
        code=(`sed -n '/'您的好友助力码为'.*/'p ${1} | awk '{print $2}'`)
        [ -z "$code" ] && code=(`sed -n '/'好友助力码'.*/'p ${1} | awk -F "：" '{print $2}'`)
        [ -z "$code" ] && exit 0
        for i in `seq 0 $((${#name[*]}-1))`
        do 
            echo "${name[i]}""${code[i]}" >> ./${LOG}1
        done
    else
        echo $code | awk '{for(i=1;i<=NF;i++)print $i}' > ./${LOG}1
    fi
}

# 任务函数
task(){
    jk="$1"
    num=$2
    [ ! -d ${SCRIPT_DIR}${num} ] && cp  -rf ${SCRIPT_DIR} ${SCRIPT_DIR}${num}
    cd ${SCRIPT_DIR}${num}
    sed -i 's/let CookieJDs/let CookieJDss/g' ./jdCookie.js
    sed -i "1i\let CookieJDs = [ '$jk', ]" ./jdCookie.js
    autoHelp "$SCRIPT" "${home}/${SCRIPT_NAME}.conf" $num
	
	if [ -n "$SKD" -a "$SKD" != "delay" ]; then
		DELAY=${DELAY:-0}
		nextdate=`act_by_min $time`
		now=`date +%s%N`
		delay=`echo "scale=3;$((nextdate-now))/1000000000" | bc`
		int_delay=`echo $delay | awk -F "." '{print $1}'`
		if [ ! -n `echo "$SKD"|grep ":"` ]; then
			now=`date +%s%N`
			delay=`echo "scale=3;$((nextdate-now))/1000000000" | bc`
			int_delay=`echo $delay | awk -F "." '{print $1}'`
			if [ $nextdate -gt $now ];then 
				[ $((int_delay - 0)) -le 300 ] && echo "未到当天${timer}，等待${delay}秒" && sleep $delay || echo "已过${timer}，但在五分钟内，继续运行"
			fi
		else
			if [ $nextdate -gt $now ];then 
				[ $((int_delay - 0)) -le 3600 ] && echo "未到当天${timer}，等待${delay}秒" && sleep $delay || echo "已过${timer}，但在一小时内，继续运行"
			fi
		fi		
	fi
    (node ./${SCRIPT} | grep -Ev "pt_pin|pt_key") >&1 | tee "./${LOG}"
    collectSharecode "./${LOG}"
    cd -
    # 随机延迟5-12秒
    random_time=$(($RANDOM%12+5))
    delay=${DELAY:-$random_time}
    echo "随机延迟${delay}秒"
    sleep ${delay}s
}

# 主函数
main(){
	[ -z "$SCRIPT" ] && echo "参数错误，需指定要运行的脚本"
	modify_scripts
# 设置时区
	sudo rm -f /etc/localtime
	sudo ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    
	echo "开始多账号并发"
	IFS=$'\n'

	format_sc2txt "${SHCD_DIR}/${SCRIPT_NAME}.log" "${home}/${SCRIPT_NAME}.conf"
	
	echo "修改cookie"
	cd ${SCRIPT_DIR}
	cp -f ./jdCookie.js ./jdCookie.bk.js
	sed -i 's/process.env.JD_COOKIE/process.env.JD_COOKIES/g' ./jdCookie.js
	# 兼容 换行 和 & 分割cookie
	if [ -n `echo "$JD_COOKIE" | grep "&"` ]; then
		JK_LIST=(`echo "$JD_COOKIE" | awk -F "&" '{for(i=1;i<=NF;i++) print $i}'`)
	else
		JK_LIST=(`echo "$JD_COOKIE" | awk -F "$" '{for(i=1;i<=NF;i++){{if(length($i)!=0) print $i}}'`)
	fi
	for jkl in `seq 1 ${#JK_LIST[*]}`
	do
		task ${JK_LIST[$((jkl-1))]} $jkl &
	done
	echo "有账号" ${#JK_LIST[*]}
	unset IFS

	wait
	
	# 整合推送消息和助力码
	for n in `seq 1 ${#JK_LIST[*]}`
	do
		cd ${SCRIPT_DIR}${n}
		[ -e "./${LOG}1" ] && cat ./${LOG}1  | sed  "s/账号[0-9]/账号$n/g" | sed "s/京东号 [0-9]/京东号$n/g" >> ${home}/${LOG}
		if [ -e "./${NOTIFY_CONF}" ]; then
			echo "" >> ${home}/${NOTIFY_CONF}
			echo "" >> ${home}/${NOTIFY_CONF}spec
			if [ $(specify_send ./${NOTIFY_CONF}) -eq 0 ];then
				cat ./${NOTIFY_CONF} | sed "s/账号[0-9]/账号$n/g" | sed "s/京东号 [0-9]/京东号$n/g" >> ${home}/${NOTIFY_CONF}
			else
				cat ./${NOTIFY_CONF} | sed "s/账号[0-9]/账号$n/g" | sed "s/京东号 [0-9]/京东号$n/g" >> ${home}/${NOTIFY_CONF}spec
			fi
			[ ! -e "${home}/${NOTIFY_CONF}name" ] && cat ./${NOTIFY_CONF}name > ${home}/${NOTIFY_CONF}name 
			# 清空文件
			rm -f ./${NOTIFY_CONF}*
			rm -f ./${NOTIFY_CONF}name
		fi
	done

	cd ${SCRIPT_DIR}
	echo "推送消息"
	if [ -n "$DD_BOT_TOKEN_SPEC" -a -n "$DD_BOT_SECRET_SPEC" ]; then
		cp -f ./sendNotify_diy.js ./sendNotify.js
		sed -i 's/text}\\n\\n/text}\\n/g' ./sendNotify.js
		sed -i 's/\\n\\n本脚本/\\n本脚本/g' ./sendNotify.js
		sed -i  "s/text = text.match/\/\/text = text.match/g" ./sendNotify.js

		if [ -e ${home}/${NOTIFY_CONF} -a -n "$(cat ${home}/${NOTIFY_CONF} | sed '/^$/d')" ]; then
			blank_lines2blank_line ${home}/${NOTIFY_CONF}
			blank_lines2blank_line ${home}/${NOTIFY_CONF}name
			node ./run_sendNotify.js
		fi
		# 特殊推送
		if [ -e ${home}/${NOTIFY_CONF}spec -a -n "$(cat ${home}/${NOTIFY_CONF}spec | sed '/^$/d')" ]; then
			blank_lines2blank_line ${home}/${NOTIFY_CONF}spec
			sed -i "s/process.env.DD_BOT_TOKEN/process.env.DD_BOT_TOKEN_SPEC/g" ./sendNotify.js
			sed -i "s/process.env.DD_BOT_SECRET/process.env.DD_BOT_SECRET_SPEC/g" ./sendNotify.js
			node ./run_sendNotify_spec.js
		fi
		# 恢复原文件
		cp -f ./sendNotify_diy.js ./sendNotify.js
	fi
	
	upload_code "${SHCD_DIR}" ${home}/${LOG} ./${LOG}
	
	# 恢复原文件
	cp -f ${SCRIPT_DIR}/jdCookie.bk.js ${SCRIPT_DIR}/jdCookie.js
	# 清空文件
	rm -f ${home}/${NOTIFY_CONF}*
	rm -f ${home}/${LOG}
}

# 清除连续空行为一行和首尾空行
blank_lines2blank_line(){
	# $1: 文件名
    # 删除连续空行为一行
    cat -s $1 > $1.bk
    mv -f $1.bk $1
    #清除文首文末空行
    [ "$(cat $1 | head -n 1)"x = ""x ] && sed -i '1d' $1
    [ "$(cat $1 | tail -n 1)"x = ""x ] && sed -i '$d' $1
}

# 判断是否需要特别推送
specify_send(){
  ret=`cat $1 | grep "提醒\|已超时\|已可兑换\|已失效\|重新登录\|已可领取\|未选择商品"`
  [ -n "$ret" ] && echo 1 || echo 0
}

# 上传助力码
upload_code(){
# $1：克隆仓库目录
# $2：助力码文件
# $3：仓库本地助力码文件
	[ ! -e $2 -o -z "$GITHUB_TOKEN" ] && echo "退出脚本" && return 0

	echo "上传助力码文件"
	cd $1
	echo "拉取最新源码"
	git config --global user.email "tsuyoshi727@qq.com"
	git config --global user.name "tsuyoshi727"
	git pull origin "$REPO_BRANCH:$REPO_BRANCH"
	
	echo "Resetting origin to: https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
	sudo git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
	
	echo "强制覆盖原文件"
	mv -v $2 $3
	git add .
	git commit -m "update ${SCRIPT_NAME} `date +%Y%m%d%H%M%S`" 2>/dev/null
	
	echo "Pushing changings from tmp_upstream to origin"
	sudo git push origin "$REPO_BRANCH:$REPO_BRANCH" --force
}
main 
