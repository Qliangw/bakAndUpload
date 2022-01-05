#!/bin/sh

path=$(cd `dirname $0` || exit;pwd)
#source user.conf
# get key
RET=$(curl -s https://qyapi.weixin.qq.com/cgi-bin/gettoken?"corpid="${CORPID}"&corpsecret="${CORP_SECRET}"")
KEY=$(echo ${RET} | jq -r .access_token)

if [[ ${MEDIA_ID} == "" ]]; then
    cat>./tmp<<EOF
{
    "touser" : "${TOUSER}",
    "msgtype" : "text",
    "agentid" : "${AGENTID}",
    "text" :
    {
        "content" : "$1"
    }
}
EOF
	else
		cat>./tmp<<EOF
{
   "touser" : "${TOUSER}",
   "msgtype" : "mpnews",
   "agentid" : "${AGENTID}",
   "mpnews" : {
       "articles":[
           {
               "title": "数据备份通知", 
               "thumb_media_id": "${MEDIA_ID}",
               "author": "备份通知",
               "content_source_url": "URL",
               "content": "$1",
               "digest": "$2"
            }
       ]
   },
   "safe":0,
   "enable_id_trans": 0,
   "enable_duplicate_check": 0,
   "duplicate_check_interval": 1800
}
EOF
fi

curl -d @tmp -XPOST https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token="${KEY}"
echo ""
rm tmp
