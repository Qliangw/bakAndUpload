# bakAndUpload

[TOC]

## 脚本说明

这是一个备份脚本，实现自动压缩加密并上传至网盘。

This is a backup script that automatically compresses, encrypts and uploads to a network drive.

配合rclone使用，可以同步至云盘，若未安装仅仅备份到本地。

## 基础环境

1. tar-压缩工具（压缩使用）
2. jq-json工具（推送使用）
3. rclone-云盘工具（上传云盘使用）

> 测试环境为unraid体系，理论上linux安装上述工具后均可使用

## 使用
### 文件说明
|文件|功能|备注|
|---|---|---|
|user.conf.default | 用户配置文件 |建议不要修改 |
|backupData.sh | 备份脚本 | |
|push.sh | 推送脚本 | |
### 配置说明
|参数| 描述 | 备注 |
|---|---|---|
|LOG_DIR | 日志目录 | 必须存在 |
|DATA_DIR|备份源目录| 必须存在 |
|IGNORE_DIR|源目录下忽略的文件夹| 可选 |
|TAR_PASSWD|压缩密码| 必须配置 |
|BAK_ROOT_DIR|备份目的目录 | 必须存在 |
|BAK_DIR|临时目录|建议不要修改 |
|RCLONE_CONF| rclone网盘配置名称|  |
|NET_DIR| 网盘目录||
|CORPID| 企业ID |必须|
|CORP_SECRET| 应用密钥 |必须|
|AGENTID| 应用ID |必须|
|MEDIA_ID| 图片ID |可选|
|TOUSER| 通知人员 |@all为全员|

### 脚本说明

![](https://raw.githubusercontent.com/Qliangw/bakAndUpload/main/img/help.png)

两种模式：

1. 自动模式，默认每天运行一次，检测到已备份后跳过
2. 手动模式，还没开始搞（目前仅仅备份至本地）

### 使用方法

1. [配置rclone](https://p3terx.com/archives/rclone-installation-and-configuration-tutorial.html)

2. 安装jq

   1. ubuntu安装 `sudo apt-get install jq`

   2.   [centos参考](https://www.jianshu.com/p/a540d121e651) 

      ```bash
      wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-1.5.tar.gz
      tar -xzvf jq-1.5.tar.gz 
      cd jq-1.5/
      ./configure && make && sudo make install
      ```

3. 将本脚本clone至本地 `git clone https://github.com/Qliangw/bakAndUpload.git`
4. 进入到bakAndUpload目录复制用户配置文件 `cp user.conf.default user.conf`
5. 根据配置说明完成配置
   1. 企业微信通知参考
6. 测试 `bash bakAndUpload.sh -a`
7. 添加定时任务

---------

> 准备增加的功能
>
> - [x] 黑名单模式
> - [ ] 白名单模式
> - [x] 完成后推送通知
>   - 备份的内容
>   - 文件夹大小
>   - 文件名称

## 免责声明

- 本项目遵守[MIT License](https://github.com/Qliangw/bakAndUpload/blob/v0.0.1/LICENSE)，因使用造成的任何损失，纠纷等，和开发者无关，请各位知悉。

## 鸣谢

- 感谢群友的提供脚本

- 感谢朋友提供的html模板

