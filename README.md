# bakAndUpload

## 说明

这是一个备份脚本，实现自动压缩加密并上传至网盘。

This is a backup script that automatically compresses, encrypts and uploads to a network drive.

配合rclone使用，可以同步至云盘，若未安装仅仅备份到本地。

## 使用

|文件|功能|备注|
|---|---|---|
|user.conf.default | 用户配置文件 | |
|backupData.sh | 脚本文件 | |
|push.sh | 推送脚本 | |
| |  | |

### 配置说明

|参数| 描述 | 备注 |
|---|---|---|
| LOG_DIR | 日志目录 | |
|DATA_DIR|备份源目录| |
|IGNORE_DIR|源目录下忽略的文件夹| |
|TAR_PASSWD|压缩密码| |
|BAK_ROOT_DIR|备份目的目录 | |
|BAK_DIR|含日期的备份目录| |
|RCLONE_CONF| rclone网盘配置名称| |
|NET_DIR| 网盘目录|还没做呢|

### 脚本说明

1. 自动模式，默认每天运行一次，检测到已备份后跳过
2. 手动模式，还没开始搞

---------

> 准备增加的功能
> 
> 1. 黑名单模式
> 2. 白名单模式
> 3. 完成后推送通知
>   - 备份的内容
>   - 文件夹大小

