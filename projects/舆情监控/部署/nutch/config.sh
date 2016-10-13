#!/bin/sh

########################################################################
#           爬取配置
########################################################################
# 爬虫代码。对应数据库表T_CRAWL_M_CRAWLER中的CRAWL_CODE字段值，表示使用这个爬虫
CRAWL_CODE=nutch
# 爬取标识，区分同台机器上的多个爬虫，由all.sh统一修改
START_FLAG=
#抓取深度
DEPTH=4
# 每个深度最多获取的URL数
MAX_URLS_PER_DEPTH=50000

# 爬取工具nutch所在目录，多个用空格分隔
NUTCH_HOMES="nutch0 nutch1 nutch2 nutch3 nutch4 nutch5 nutch6 nutch7 nutch8 nutch9"

# 多个爬虫并发数。默认1
CRAWL_CONCURRENT=3

# 主机IP地址。为空则自动获取
HOST_IP=

# 每个爬虫并发线程数
numSlaves=1

# 清理时是否清理爬取目录下的所有文件（包含crawldb、linkdb、segments）。true 全部删除，false仅删除segments，其他值不清理。默认不清理
NEED_CLEAN_ALL=false

# 爬取种子所在目录短名
CRAWL_SEED_PATH_NAME=urls

# 爬取数据保存的目录短名
CRAWL_DATA_PATH_NAME=datas
# 程序运行脚本名
CRAWL_SCRIPT=run.sh
# 爬虫状态文件相对路径（基于爬虫根目录${NUTCH_HOME}）
LOCK_FILE=logs/.lock

# NUTCH自身日志文件名
NUTCH_LOGFILE=hadoop.log
########################################################################
#           数据库配置
########################################################################
#任务执行的结果需要写入的mysql数据库ip
db_ip=localhost
#任务执行的结果需要写入的mysql数据库端口
db_port=3306
#任务执行的结果需要写入的mysql数据库登陆用户名
db_user=mysql
#任务执行的结果需要写入的mysql数据库登陆密码
db_passwd=mysql123
#任务执行的结果需要写入的mysql数据库的数据库名称
db_instance=common
#任务执行的结果需要写入的mysql数据库的数据库表名
db_table_crawl_log=T_CRAWL_R_CRAWLER_STATUS

#字符集
charset=UTF8
#执行语句
MYSQL_CMD="mysql -N -h${db_ip} -P${db_port} -u${db_user} -p${db_passwd} --default-character-set=${charset} -D${db_instance} -e"

execute_query()
{
    SQL=$1
    #echo SQL="$execmd \"$SQL\""
    $MYSQL_CMD "$SQL"
    #echo execute sql result code: $?
}
