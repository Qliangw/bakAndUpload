#!/bin/bash

versionX="0.1.1"
updateX="2022-01-17"

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
	local LOG_MSG;local LOG_TYPE
	LOG_TYPE="$1"
	LOG_MSG="$2"
	datetime=$(date +'%Y/%m/%d %H:%M:%S')
	#使用内置变量$LINENO不行，不能显示调用那一行行号
	#LOG_FORMAT="[${LOG_TYPE}]\t${datetime}\tfuncname:${FUNCNAME[@]} [line:$LINENO]\t${LOG_MSG}"
	#LOG_FORMAT="[${LOG_TYPE}]\t${datetime}\tfuncname: ${FUNCNAME[@]/log/}\t[line:`caller 0 | awk '{print$1}'`]\t${LOG_MSG}"
	#LOG_FORMAT="${datetime}\t${LOG_TYPE}\t:${FUNCNAME[@]/log/}\t[line:$(caller 0 | awk '{print$1}')]\t${LOG_MSG}"
	LOG_FORMAT="${datetime}\t${LOG_TYPE}\t:${LOG_MSG}"
	{
	case $LOG_TYPE in  
                debug)
                        [[ $LOG_LEVEL -le 0 ]] && echo -e "\033[30m${LOG_FORMAT}\033[0m" ;;
                info)
                        [[ $LOG_LEVEL -le 1 ]] && echo -e "\033[32m${LOG_FORMAT}\033[0m" ;;
                warn)
                        [[ $LOG_LEVEL -le 2 ]] && echo -e "\033[33m${LOG_FORMAT}\033[0m" ;;
                error)
                        [[ $LOG_LEVEL -le 3 ]] && echo -e "\033[31m${LOG_FORMAT}\033[0m" ;;
    esac
	} # | tee -a $LOG_FILE
	#LOG_HEAD_INFO="[$(date '+%H:%M:%S.%3N')]"
	#echo -e "$LOG_HEAD_INFO" "$1" | tee -a "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" 2>&1 
}

function log_output_split()
{
	printf -v str "%${1}s" ""
	echo "${str// /$2}" | tee -a "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" 2>&1 
}

function action_backup()
{
	cd "${DATA_DIR}" || exit
	log_output info "开始备份appdata数据..." 
	IGNORE_DIR_FINAL=$(echo ${IGNORE_DIR: -1})
	if [[ "${IGNORE_DIR_FINAL}" == "," ]]; then
		IGNORE_DIR_TRANSFORM=$(echo ${IGNORE_DIR%?} | sed 's/,/\\|/g')
	else
		IGNORE_DIR_TRANSFORM=$(echo ${IGNORE_DIR} | sed 's/,/\\|/g')
	fi
	cp -r $(ls "${DATA_DIR}" | grep -v "${IGNORE_DIR_TRANSFORM}" | xargs) "${BAK_DIR}"
	log_output info "备份appdata数据完成！" 
}

function create_dir()
{
	log_output info "本次备份目录不存在" 
	mkdir "${BAK_ROOT_DIR}"/bak_appdata_"${DATA_FILE_NAME}"
	log_output info "创建bak_appdata目录" 
}

function comp_file()
{
	# 进入备份目录的上一级目录
	cd "${BAK_ROOT_DIR}" || exit
	log_output info "开始压缩appdata备份数据..." 
	
	# zip 压缩
	# zip -rmP password unraid_appdata_bak_$(date +"%Y-%m-%d").zip "${BAK_DIR}"

	# tar -zc 使用gzip压缩
	# 解压命令：openssl des3 -d -k password -salt -in files.tar.gz | tar xzvf -
	# 压缩 删除原文件 加密 以日期命名
	tar -czf - "${BAK_DIR}" --remove-files \
		| openssl des3 -salt -k "${TAR_PASSWD}" \
		| dd of=bak_appdata_"$(date +'%Y-%m-%d')".tar.gz 
		# | tee -a "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" 2>&1
	log_output info "加密压缩完成！" 
}

function action_shell()
{
	if [ -f "${BAK_ROOT_DIR}/bak_appdata_"${DATA_FILE_NAME}".tar.gz" ];then
		log_output warn "今日已备份！" 
	else
		if [ -d "${BAK_ROOT_DIR}/bak_appdata_"${DATA_FILE_NAME}"" ];then
		    log_output warn "本次备份目录已存在" 
		else
		    create_dir
		    action_backup
		fi
		comp_file
	fi
}

function start_rclone()
{
	if ! [ -x "$(command -v rclone)" ];then
		log_output error "rclone未安装,仅备份至本地"
		exit 1
	fi
	log_output info "开始上传..."
	rclone copy -v "${BAK_ROOT_DIR}/bak_appdata_"${DATA_FILE_NAME}".tar.gz" "${RCLONE_CONF}":"${NET_DIR}"/"$(date +'%m-%d')" >> "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" 2>&1
	log_output info "完成上传!"
}

function bak_comp()
{
	cd "${BASE_ROOT}" || exit
	source ./user.conf
	#设置日志级别
	LOG_LEVEL=1 #debug:0; info:1; warn:2; error:3
	LOG_FILE="${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log"
	#log_output_split 32 '*'
	log_output info "导入用户配置"
	log_output info "运行脚本： $0"
	action_shell
	#log_output_split 32 '-'
	#echo -e | tee -a "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" 2>&1
}

# 删除旧备份
function rm_oldbak()
{
	log_output info "开始清理旧文件..."
	log_output info "清理${LOCAL_BAK_DAY}天以上的备份"
	find "${BAK_ROOT_DIR}" -mtime +${LOCAL_BAK_DAY} -name "*.tar.gz"  -type f -print -exec rm -rf {} \;
	log_output info "清理${LOG_DAY}天以上的日志"
	find "${LOG_DIR}" -mtime +${LOG_DAY} -name "*.log"  -type f -print -exec rm -rf {} \;
	log_output info "清理完成！"
}

function push_wx()
{
	log_output info "推送信息中..."

	# cd "${BASE_ROOT}" || exit
	#TMP_F="$(grep -e "[0-9].[0-9]s" "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" | tail -1)"
	TMP_S="$(grep -e "[0-9]*.[0-9]* MiB/s" "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" | tail -1)"
	TMP_T="$(grep -e "[0-9].[0-9]s" "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" | tail -1)"
	#TMP_V="$(grep -e "[0-9].[0-9]s" "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log" | tail -1)"
	#PUSH_MSG=$(cat "${LOG_DIR}/backupData_"${DATA_FILE_NAME}".log")
	RCLONE_F="bak_appdata_"${DATA_FILE_NAME}".tar.gz"
	RCLONE_S="$(echo ${TMP_S#*/} | cut -d ',' -f 1)"
	RCLONE_T="$(echo ${TMP_T#*:})"
	RCLONE_V="$(echo ${TMP_S#*%,} | cut -d ',' -f 1)"
	if [[ $(echo ${IGNORE_DIR: -1}) == "," ]]; then
		IGNORE_DIR_PUSH=$(echo "${IGNORE_DIR%?}")
	else
		IGNORE_DIR_PUSH=${IGNORE_DIR}
	fi
	PUSH_DIGEST="文件名称\t：${RCLONE_F}\n忽略文件\t："${IGNORE_DIR_PUSH}"\n文件大小\t：${RCLONE_S}\n平均速度\t：${RCLONE_V}\n上传用时\t：${RCLONE_T}"
	PUSH_CONTENT="$(echo "$PUSH_DIGEST" | sed 's/\\n/\<br\/\>/g')"
	# push 参数1(html格式) 参数2(文本格式)
	bash "${BASE_ROOT}"/push.sh "${PUSH_CONTENT}" "${PUSH_DIGEST}"
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
	exit 0
}

version()
{
	echo -e "--Version:${versionX}" "\\n--update time:${updateX}"
	exit 0
}

# rclone copy -v "${BAK_ROOT_DIR}/bak_appdata_"${DATA_FILE_NAME}".tar.gz" aliyunwebdav-zx:/webdav/backup/unraid/$(date +"%m-%d")/ > "/mnt/disk1/rclone-tr.log" 2>&1



# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑


# *****************3. 执行*****************
# ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

if [[ "$1" == "-m" || "$1" == "manual" ]]; then
	bak_comp
elif [[ "$1" == "-a" || "$1" == "auto" ]]; then
	bak_comp
	rm_oldbak
	start_rclone
	push_wx
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
	display_help
elif [[ "$1" == "-v" || "$1" == "--version" ]]; then
	version
elif [[ "$1" == "test" ]]; then
	push_wx
else
	#echo "请输出-h 查看正确命令！"
	echo -e "\033[33m请输出-h 查看正确命令！\033[0m"
fi
# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
log_output info "退出脚本"
exit 0
