#!/bin/bash

# *****************1. 配置*****************
# ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
BASE_ROOT=$(cd "$(dirname "$0")";pwd)
#BAK_DIR="${BAK_ROOT_DIR}/bak_appdata_`date '+%F'`"
# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑


# *****************2. 函数*****************
# ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
function logOutput()
{
	LOG_HEAD_INFO="["`date '+%F %H:%M:%S.%3N'`"]"
	echo $LOG_HEAD_INFO $1 | tee -a "${LOG_DIR}/rclone_`date '+%F'`.log" 2>&1 
}

function logOutputSplit()
{
	printf -v str "%${1}s" ""
	echo "${str// /$2}" | tee -a "${LOG_DIR}/rclone_`date '+%F'`.log" 2>&1 
}

function actionBackup()
{
	cd ${DATA_DIR}
	logOutput "开始备份appdata数据..." 
	cp -r `ls ${DATA_DIR} | grep -v ${IGNORE_DIR} | xargs` ${BAK_DIR}
	logOutput "备份appdata数据完成！" 
}

function createDir()
{
	logOutput "本次备份目录不存在" 
    mkdir ${BAK_ROOT_DIR}/bak_appdata_`date '+%F'`
    logOutput "创建bak_appdata目录" 
}

function compFile()
{
	# 进入备份目录的上一级目录
	cd ${BAK_ROOT_DIR}
	logOutput "开始压缩appdata备份数据..." 
	
	# zip 压缩
	# zip -rmP password unraid_appdata_bak_$(date +"%Y-%m-%d").zip ${BAK_DIR}

	# tar -zc 使用gzip压缩
	# 解压命令：openssl des3 -d -k password -salt -in files.tar.gz | tar xzvf -
	# 压缩 删除原文件 加密 以日期命名
	tar -czf - ${BAK_DIR} --remove-files \
		| openssl des3 -salt -k password \
		| dd of=bak_appdata_$(date +"%Y-%m-%d").tar.gz \
		| tee -a "${LOG_DIR}/rclone_`date '+%F'`.log" 2>&1
	logOutput "加密压缩完成！" 

}

function actionShell()
{
	if [ -f "${BAK_ROOT_DIR}/bak_appdata_`date '+%F'`.tar.gz" ];then
		logOutput "今日已备份！" 
	else
		if [ -d "${BAK_ROOT_DIR}/bak_appdata_`date '+%F'`" ];then
		    logOutput "本次备份目录已存在" 
		else
		    createDir
		    actionBackup
		fi

		compFile
	fi
}

function checkRclone()
{
	if ! [ -x "$(command -v rclone)" ];then
		logOutput "rclone未安装"
		exit 1
	fi
}

function bakComp()
{
	logOutputSplit 64 \*
	cd ${BASE_ROOT}
	source user.conf
	logOutput "导入用户配置"
	logOutput "运行脚本： $0"
	actionShell
	logOutputSplit 64 \=
	echo -e | tee -a "${LOG_DIR}/rclone_`date '+%F'`.log" 2>&1 

}


# 帮助文档
displayHelp()
{
	echo "Usage: $0 [option...] {manual|auto}" >&2
	echo "   -m, manual              手动模式"
    echo "   -a, auto                自动模式"
    echo "   -v, --version           版本信息"
    echo "   -h, --help              帮助信息"
    echo
    # echo some stuff here for the -a or --add-options 
    exit 1
}

version()
{
	echo -e "version:0.0.1"\\nupdate time:2021-12-31
}

# rclone copy -v "${BAK_ROOT_DIR}/bak_appdata_`date '+%F'`.tar.gz" aliyunwebdav-zx:/webdav/backup/unraid/$(date +"%m-%d")/ > "/mnt/disk1/rclone-tr.log" 2>&1

# rclone copy -v "${BAK_ROOT_DIR}/bak_appdata_`date '+%F'`.tar.gz" aliyunwebdav-zx:/webdav/backup/unraid/$(date +"%m-%d")/ | tee -a "${LOG_DIR}/rclone_`date '+%F'`.log" 2>&1

# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑


# *****************3. 执行*****************
# ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

if [[ "$1" == "-m" || "$1" == "manual" ]]; then
	bakComp
elif [[ "$1" == "-a" || "$1" == "auto" ]]; then
	bakComp
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
	displayHelp
elif [[ "$1" == "-v" || "$1" == "--version" ]]; then
	version
else
	echo "请输出-h 查看正确命令！"
fi
# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
exit 0