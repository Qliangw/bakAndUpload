#!/bin/bash

# *****************1. 配置*****************
# ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
BASE_ROOT=$(cd "$(dirname "$0")" || exit;pwd)
#BAK_DIR="${BAK_ROOT_DIR}/bak_appdata_"${DATA_FILE_NAME}""
DATA_FILE_NAME=$(date '+%F')
# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑


# *****************2. 函数*****************
# ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
function log_output()
{
	LOG_HEAD_INFO="[$(date '+%F %H:%M:%S.%3N')]"
	echo "$LOG_HEAD_INFO" "$1" | tee -a "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" 2>&1 
}

function log_output_split()
{
	printf -v str "%${1}s" ""
	echo "${str// /$2}" | tee -a "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" 2>&1 
}

function action_backup()
{
	cd "${DATA_DIR}" || exit
	log_output "开始备份appdata数据..." 
	cp -r $(ls "${DATA_DIR}" | grep -v "${IGNORE_DIR}" | xargs) "${BAK_DIR}"
	log_output "备份appdata数据完成！" 
}

function create_dir()
{
	log_output "本次备份目录不存在" 
    mkdir "${BAK_ROOT_DIR}"/bak_appdata_"${DATA_FILE_NAME}"
    log_output "创建bak_appdata目录" 
}

function comp_file()
{
	# 进入备份目录的上一级目录
	cd "${BAK_ROOT_DIR}" || exit
	log_output "开始压缩appdata备份数据..." 
	
	# zip 压缩
	# zip -rmP password unraid_appdata_bak_$(date +"%Y-%m-%d").zip "${BAK_DIR}"

	# tar -zc 使用gzip压缩
	# 解压命令：openssl des3 -d -k password -salt -in files.tar.gz | tar xzvf -
	# 压缩 删除原文件 加密 以日期命名
	tar -czf - "${BAK_DIR}" --remove-files \
		| openssl des3 -salt -k password \
		| dd of=bak_appdata_"$(date +'%Y-%m-%d')".tar.gz \
		| tee -a "${LOG_DIR}/rclone_"${DATA_FILE_NAME}".log" 2>&1
	log_output "加密压缩完成！" 
}

function action_shell()
{
	if [ -f "${BAK_ROOT_DIR}/bak_appdata_"${DATA_FILE_NAME}".tar.gz" ];then
		log_output "今日已备份！" 
	else
		if [ -d "${BAK_ROOT_DIR}/bak_appdata_"${DATA_FILE_NAME}"" ];then
		    log_output "本次备份目录已存在" 
		else
		    create_dir
		    action_backup
		fi
		comp_file
	fi
}

function check_rclone()
{
	if ! [ -x "$(command -v rclone)" ];then
		log_output "rclone未安装"
		exit 1
	fi
}

function bak_comp()
{
	cd "${BASE_ROOT}" || exit
	source ./user.conf
	log_output_split 64 '*'
	log_output "导入用户配置"
	log_output "运行脚本： $0"
	action_shell
	log_output_split 64 '='
	echo -e | tee -a "${LOG_DIR}/rclone_"${DATA_FILE_NAME}".log" 2>&1
}

function push_wx()
{
	cd "${BASE_ROOT}" || exit
	bash ./push.sh "测试通知" 

}

# 帮助文档
display_help()
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

# rclone copy -v "${BAK_ROOT_DIR}/bak_appdata_"${DATA_FILE_NAME}".tar.gz" aliyunwebdav-zx:/webdav/backup/unraid/$(date +"%m-%d")/ > "/mnt/disk1/rclone-tr.log" 2>&1



# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑


# *****************3. 执行*****************
# ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

if [[ "$1" == "-m" || "$1" == "manual" ]]; then
	bak_comp
elif [[ "$1" == "-a" || "$1" == "auto" ]]; then
	bak_comp
	log_output_split 10 '-'
	rclone copy -v "${BAK_ROOT_DIR}/bak_appdata_"${DATA_FILE_NAME}".tar.gz" "${RCLONE_CONF}":"${NET_DIR}"/"$(date +'%m-%d')" >> "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" 2>&1
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
	display_help
elif [[ "$1" == "-v" || "$1" == "--version" ]]; then
	version
elif [[ "$1" == "test" ]]; then
	push_wx
else
	echo "请输出-h 查看正确命令！"
fi
# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
exit 0