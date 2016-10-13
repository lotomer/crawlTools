#!/bin/sh
#set -x
WORK_HOME=$(cd $(dirname $0);pwd)
#echo NUTCH_HOME=${NUTCH_HOME}
OPER=$1

CONFIG_FILE_NAME=config.sh
CONFIG_FILE=${WORK_HOME}/$CONFIG_FILE_NAME
MAIN_STATE_FILE=${WORK_HOME}/state.log
MAIN_LOG_FILE=${WORK_HOME}/start.log
MAIN_STOP_FILE=${WORK_HOME}/ALL.STOP
# 使配置文件生效
. $CONFIG_FILE

# 将爬虫转化为数组
declare -a  NUTCH_HOME_ARRAY

NUTCH_INDEX=0
for NUTCH_HOME in $NUTCH_HOMES
do
    if [ -d $NUTCH_HOME ]; then
        # 目录不存在，则不放到队列中来
        NUTCH_HOME_ARRAY[$NUTCH_INDEX]=$NUTCH_HOME
        NUTCH_INDEX=$((NUTCH_INDEX+1))
    else
        echo "$NUTCH_HOME is not a directory, or not exists!"
    fi
done
NUTCH_HOMES_SIZE=( ${#NUTCH_HOME_ARRAY[@]} )

if [ "$CRAWL_CODE" = "" ];then
    CRAWL_CODE=nutch
fi
if [ "$CRAWL_CONCURRENT" = "" ];then
    CRAWL_CONCURRENT=1
fi
##########################################################
print_usage ()
{
    echo "Usage: $0 OPER(status|start|stop|forcestart|forcestop|restart|state|distributeFiles|init|deleteStatusFile|clean)"
}
distribute_files ()
{
    K=0
    for NUTCH_HOME in ${NUTCH_HOME_ARRAY[*]}
    do
        echo "Distribute files to $NUTCH_HOME"
        cp -f $WORK_HOME/$CRAWL_SCRIPT "$NUTCH_HOME"
        #cp -f $CONFIG_FILE "$NUTCH_HOME"
        sed 's/^START_FLAG=.*$/START_FLAG='$K'/g' "$CONFIG_FILE" > "$NUTCH_HOME/$CONFIG_FILE_NAME"
        cp -f $WORK_HOME/nutch-site.xml "$NUTCH_HOME/conf/"
        #cp -f $WORK_HOME/crawl "$NUTCH_HOME/bin/"
        sed 's/^sizeFetchlist=.*$/sizeFetchlist=`expr $numSlaves \\* '$MAX_URLS_PER_DEPTH'`/g' "$WORK_HOME/crawl" | sed 's/^NUTCH_LOGFILE=.*/NUTCH_LOGFILE='$NUTCH_LOGFILE'/g' | sed 's/^numSlaves=.*/numSlaves='$numSlaves'/g' > "$NUTCH_HOME/bin/crawl"
        
        K=$((K+1))
    done 
}
# 数据清理
clean ()
{
    for NUTCH_HOME in ${NUTCH_HOME_ARRAY[*]}
    do
        sh $NUTCH_HOME/$CRAWL_SCRIPT clean
    done
    
    #删除主程序停止标识
    if [ -e "$MAIN_STOP_FILE" ]; then
        rm -f "$MAIN_STOP_FILE"
    fi
}
# 清理状态文件。爬虫异常终止可能导致状态文件没有及时清理，妨碍程序正常启动
deleteStatusFile ()
{
    for NUTCH_HOME in ${NUTCH_HOME_ARRAY[*]}
    do
        sh $NUTCH_HOME/$CRAWL_SCRIPT deleteStatusFile
    done
}
do_init()
{
    INIT_FLAG=$1
    for NUTCH_HOME in ${NUTCH_HOME_ARRAY[*]}
    do
        # 首先判断是否正在运行，如果在运行则退出
        # 只要有一个还在运行，则不能继续
        if [ "$INIT_FLAG" = "true" -a -f "$NUTCH_HOME/${LOCK_FILE}" ];then
            echo "[`date +%"Y-%m-%d %H:%M:%S"`] Cannot start, becauce this nutch is running: $NUTCH_HOME"
            return 1;
        fi
        
        # 生成通用过滤规则
        URL_FILTER_FILE=$NUTCH_HOME/conf/regex-urlfilter.txt
        echo "-^(file|ftp|mailto):">$URL_FILTER_FILE
        echo "-\.(gif|GIF|jpg|JPG|png|PNG|ico|ICO|css|CSS|sit|SIT|eps|EPS|wmf|WMF|zip|ZIP|ppt|PPT|mpg|MPG|xls|XLS|gz|GZ|rpm|RPM|tgz|TGZ|mov|MOV|exe|EXE|jpeg|JPEG|bmp|BMP|js|JS|PPTX|pptx|xlsx|XLSX|docx|DOCX|csv|CSV)$" >> $URL_FILTER_FILE
        echo '-[?*!@=]' >> $URL_FILTER_FILE
        echo '-.*(/[^/]+)/[^/]+\1/[^/]+\1/' >> $URL_FILTER_FILE
        
        #删除以前的种子
        if [ -e "$NUTCH_HOME/$CRAWL_SEED_PATH_NAME" ];then
            rm -fr "$NUTCH_HOME/$CRAWL_SEED_PATH_NAME"
        fi
        mkdir "$NUTCH_HOME/$CRAWL_SEED_PATH_NAME"
    done
    
    #将脚本下发
    distribute_files
    
    # 从数据库获取要爬取的URL列表，并均匀分布给指定的爬虫
    URLS=`execute_query "select concat(site_host,',',URL)  from T_CRAWL_C_CRAWL_URLS u left join T_CRAWL_C_SITE s on u.SITE_ID=s.SITE_ID   where u.IS_VALID=1 AND s.IS_VALID=1" 2>/dev/null`
    
    NUTCH_INDEX=0
    for ROW in $URLS
    do
        if [ "${NUTCH_HOME_ARRAY[$NUTCH_INDEX]}" = "" ];then
            NUTCH_INDEX=$((NUTCH_INDEX+1))
        fi
        if [ $NUTCH_INDEX -ge $NUTCH_HOMES_SIZE ];then
            NUTCH_INDEX=0
        fi
        NUTCH_HOME=${NUTCH_HOME_ARRAY[$NUTCH_INDEX]}
        
        HOST=`echo $ROW | cut -d "," -f1`;
        URL=`echo $ROW | cut -d "," -f2`; 

        # 生成要爬取的列表
        echo "$URL" >> "$NUTCH_HOME/$CRAWL_SEED_PATH_NAME/seed.txt"
        
        # 生成过滤规则      
        echo "+([a-zA-Z0-9]*\.)*$HOST/.*" >> "$NUTCH_HOME/conf/regex-urlfilter.txt"
        
        # 循环分配
        NUTCH_INDEX=$((NUTCH_INDEX+1))
    done
    return 0
}
# 初始化工作
init ()
{
    do_init true
    
    clean
}
start_program_bak ()
{    
    echo "[`date +%"Y-%m-%d %H:%M:%S"`]Start all programs..."
    M=0
    while((M<1))
    do
        if init; then
            SOLR_URL=`$MYSQL_CMD "select CONFIG_VALUE FROM T_U_CONFIG where  CONFIG_NAME='SOLR_URL'" 2>/dev/null`
            if [ "$SOLR_URL" = "" ]; then
                SOLR_URL=http://localhost:8983/solr
            fi
            
            if [ -f "$MAIN_STATE_FILE" ];then
                echo "Clean state file: $MAIN_STATE_FILE"
                #rm -f "$MAIN_STATE_FILE"
            fi
            # 开始启动各个爬虫
            EXIT_CODE=0
            TMP_NUTCH_INDEX=0

            for NUTCH_HOME_4_START in ${NUTCH_HOME_ARRAY[*]}
            do
                while((0<1))
                do
                    # 检查停止标识
                    if [ -e $MAIN_STOP_FILE ]; then
                        echo Catch stop flag: $MAIN_STOP_FILE
                        TMP_NUTCH_INDEX=-1
                        M=1
                        break
                    fi
                    # 不能超过并发个数
                    count_running
                    CNT=$?
                    echo "$CNT/$CRAWL_CONCURRENT"
                    if [ $CNT -lt $CRAWL_CONCURRENT ];then
                        echo "start $NUTCH_HOME_4_START ..."
                        sh $NUTCH_HOME_4_START/$CRAWL_SCRIPT start "$SOLR_URL" &
                        sleep 5
                        # 判断统计程序是否已经启动，如果启动了就不用重复启动
                        STATE_MSG=`ps -ef |grep "sh $NUTCH_HOME_4_START/$CRAWL_SCRIPT state " | grep -v grep`
                        if [ "$STATE_MSG"X = "X" ]; then
                            sh $NUTCH_HOME_4_START/$CRAWL_SCRIPT state "$SOLR_URL" >> $MAIN_STATE_FILE &
                        fi
                        sleep 30
                        
                        break
                    else
                        echo "[`date +%"Y-%m-%d %H:%M:%S"`] concurrent is full, sleep 5 seconds."
                        sleep 5
                    fi
                done
                
                #中止
                if [ $TMP_NUTCH_INDEX -lt 0 ];then
                    break
                fi
            done
            EXIT_CODE=$?
            echo "[`date +%"Y-%m-%d %H:%M:%S"`]Start ${START_COUNT} programs."
            #return $EXIT_CODE
        else
            echo "[`date +%"Y-%m-%d %H:%M:%S"`]Start failed!"
            #return 1
        fi
        
        # 检查停止标识
        if [ -e $MAIN_STOP_FILE ]; then
            echo Catch stop flag: $MAIN_STOP_FILE
            M=1
            break
        fi
        #从数据库读取爬虫配置的间隔时间（单位：分钟）
        CRAWL_FREQUENCY=`execute_query "select CRAWL_FREQUENCY  from T_CRAWL_M_CRAWLER where CRAWL_CODE='${CRAWL_CODE}' AND IS_VALID=1 LIMIT 1"  2>/dev/null`
        echo "[`date +%"Y-%m-%d %H:%M:%S"`] CRAWL_FREQUENCY=$CRAWL_FREQUENCY"
        # 下一次爬取是间隔CRAWL_FREQUENCY分钟
        echo "[`date +%"Y-%m-%d %H:%M:%S"`] Sleep $((CRAWL_FREQUENCY * 60)) seconds for next crawl..."
        sleep $((CRAWL_FREQUENCY * 60))
    done
}
start_program ()
{    
    echo "[`date +%"Y-%m-%d %H:%M:%S"`]Start all programs..."
    M=0
    while((M<1))
    do
        if init; then
            SOLR_URL=`$MYSQL_CMD "select CONFIG_VALUE FROM T_U_CONFIG where  CONFIG_NAME='SOLR_URL'" 2>/dev/null`
            if [ "$SOLR_URL" = "" ]; then
                SOLR_URL=http://localhost:8983/solr
            fi
            
            if [ -f "$MAIN_STATE_FILE" ];then
                echo "Clean state file: $MAIN_STATE_FILE"
                #rm -f "$MAIN_STATE_FILE"
            fi
            # 开始启动各个爬虫
            EXIT_CODE=0
            NUTCH_INDEX_4_START=0
            START_COUNT=0
            while((NUTCH_INDEX_4_START < NUTCH_HOMES_SIZE))
            #for NUTCH_HOME in ${NUTCH_HOME_ARRAY[*]}
            do
                NUTCH_HOME_4_START=${NUTCH_HOME_ARRAY[$NUTCH_INDEX_4_START]}
                while((0<1))
                do
                    # 检查停止标识
                    if [ -e $MAIN_STOP_FILE ]; then
                        echo Catch stop flag: $MAIN_STOP_FILE
                        NUTCH_INDEX_4_START=-1
                        break
                    fi
                    # 不能超过并发个数
                    count_running
                    CNT=$?
                    echo "[`date +%"Y-%m-%d %H:%M:%S"`] $CNT/$CRAWL_CONCURRENT"
                    if [ $CNT -lt $CRAWL_CONCURRENT ];then
                        # 判断程序是否在运行，如果在运行则不再启动
                        sh $NUTCH_HOME_4_START/$CRAWL_SCRIPT status
                        if [ $? -ne 0 ];then
                            echo "start $NUTCH_HOME_4_START ..."
                            sh $NUTCH_HOME_4_START/$CRAWL_SCRIPT start "$SOLR_URL" &
                            sleep 5
                            START_STATE_FLAG=`ps -ef|grep "sh $NUTCH_HOME_4_START/$CRAWL_SCRIPT state" | grep -v grep `
                            # 没有启动统计程序，则启动
                            if [ "$START_STATE_FLAG"X = "X" ]; then
                                sh $NUTCH_HOME_4_START/$CRAWL_SCRIPT state "$SOLR_URL" >> $MAIN_STATE_FILE &
                            fi
                            sleep 30
                            START_COUNT=$((START_COUNT+1))
                        fi
                        
                        NUTCH_INDEX_4_START=$((NUTCH_INDEX_4_START+1))
                        break
                    else
                        # 队列满了，则进行一次文件更新操作
                        do_init
                        echo "[`date +%"Y-%m-%d %H:%M:%S"`] concurrent is full, sleep 5 seconds."
                        sleep 5
                    fi
                done
                
                # 循环
                if [ $NUTCH_INDEX_4_START -ge $NUTCH_HOMES_SIZE ];then
                    NUTCH_INDEX_4_START=0
                fi
                
                #中止
                if [ $NUTCH_INDEX_4_START -lt 0 ];then
                    M=1
                    break
                fi
            done
            EXIT_CODE=$?
            echo "[`date +%"Y-%m-%d %H:%M:%S"`]Start ${START_COUNT} programs."
            #return $EXIT_CODE
        else
            echo "[`date +%"Y-%m-%d %H:%M:%S"`]Start failed!"
            #return 1
        fi
        
        # 检查停止标识
        if [ -e $MAIN_STOP_FILE ]; then
            echo Catch stop flag: $MAIN_STOP_FILE
            M=1
            break
        fi
        #从数据库读取爬虫配置的间隔时间（单位：分钟）
        CRAWL_FREQUENCY=`execute_query "select CRAWL_FREQUENCY  from T_CRAWL_M_CRAWLER where CRAWL_CODE='${CRAWL_CODE}' AND IS_VALID=1 LIMIT 1"  2>/dev/null`
        echo "[`date +%"Y-%m-%d %H:%M:%S"`] CRAWL_FREQUENCY=$CRAWL_FREQUENCY"
        # 下一次爬取是间隔CRAWL_FREQUENCY分钟
        echo "[`date +%"Y-%m-%d %H:%M:%S"`] Sleep $((CRAWL_FREQUENCY * 60)) seconds for next crawl..."
        sleep $((CRAWL_FREQUENCY * 60))
    done
}
kill_program ()
{
    STOP_OPER=$1
    for NUTCH_HOME in ${NUTCH_HOME_ARRAY[*]}
    do
        sh $NUTCH_HOME/$CRAWL_SCRIPT "$STOP_OPER" "$SOLR_URL"
    done
    
    # 设置主程序停止标识
    if [ ! -e "$MAIN_STOP_FILE" ]; then
        touch "$MAIN_STOP_FILE"
    fi
}

print_status ()
{
    for NUTCH_HOME in ${NUTCH_HOME_ARRAY[*]}
    do
        sh $NUTCH_HOME/$CRAWL_SCRIPT status "$SOLR_URL"
    done
}
count_running ()
{
    K=0
    for NUTCH_HOME_4_COUNT in ${NUTCH_HOME_ARRAY[*]}
    do
        sh $NUTCH_HOME_4_COUNT/$CRAWL_SCRIPT status "$SOLR_URL" >/dev/null
        if [ $? -eq 0 ];then
            K=$((K+1))
        fi
    done
    
    return $K
}
print_state ()
{
    if [ -f "$MAIN_STATE_FILE" ];then
        tail -fn99 "$MAIN_STATE_FILE"
    fi
}
print_state_bak ()
{
    for NUTCH_HOME in ${NUTCH_HOME_ARRAY[*]}
    do
        if [ "$CRAWL_CONCURRENT" = "true" ];then
            sh $NUTCH_HOME/$CRAWL_SCRIPT state "$SOLR_URL" &
            sleep $SLEEP_TIME_4_NEXT_CRAWLER
        else
            sh $NUTCH_HOME/$CRAWL_SCRIPT state "$SOLR_URL"
        fi
    done
}
##########################################################
if [ "$OPER"X = "X" ]; then
    print_usage
    exit 1
fi

case "$OPER" in
    start)
        start_program > $MAIN_LOG_FILE 2>&1 &
        ;;
    stop)
        echo "[`date +%"Y-%m-%d %H:%M:%S"`]Stop all programs..."
        kill_program stop
        ;;
    forcestart)
        deleteStatusFile
        sh $0 start
        ;;
    forcestop)
        echo -n "Force stopping program:"
        kill_program forcestop
        ;;
    status)
        #get_pid
        print_status
        ;;
    count_running)
        count_running
        echo Total $? running.
        ;;
    state)
        print_state
        ;;
    restart)
        sh $0 stop
        sh $0 start
        ;;
    distributeFiles)
        distribute_files
        ;;
    init)
        init
        ;;
    deleteStatusFile)
        deleteStatusFile
        ;;
    clean)
        clean
        ;;
    *)
        print_usage
        exit 1
        ;;
esac