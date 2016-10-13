#!/bin/sh
#set -x
NUTCH_HOME=$(cd $(dirname $0);pwd)
#echo NUTCH_HOME=${NUTCH_HOME}
OPER=$1
#START_FLAG=$2
SOLR_URL=$2

CONFIG_FILE=${NUTCH_HOME}/config.sh

# 使配置文件生效
. ${NUTCH_HOME}/config.sh

if [ "$CRAWL_DATA_PATH_NAME" = "" ]; then
    CRAWL_DATA_PATH_NAME=datas
fi
CRAWL_PATH=${NUTCH_HOME}/$CRAWL_DATA_PATH_NAME

if [ "$HOST_IP" = "" ]; then
    HOST_IP=`hostname --fqdn`
fi
MATCHINE="$HOST_IP($START_FLAG)"

LOG_DIR=${NUTCH_HOME}/logs
LOG_FILE=${LOG_DIR}/run.log
STATUS_FILE=${NUTCH_HOME}/${LOCK_FILE}
STATE_FILE=${LOG_DIR}/state.log
PARAMS=

if [ "$SOLR_URL" = "" ]; then
    SOLR_URL=`$MYSQL_CMD "select CONFIG_VALUE FROM T_U_CONFIG where  CONFIG_NAME='SOLR_URL'"`
    if [ "$SOLR_URL" = "" ]; then
        SOLR_URL=http://localhost:8983/solr
    fi
fi
PARAMS="-D solr.server.url=$SOLR_URL"
CRAWL_CMD="$NUTCH_HOME/bin/crawl -i ${PARAMS} $NUTCH_HOME/$CRAWL_SEED_PATH_NAME $CRAWL_PATH"

STATUS_ID=
print_usage ()
{
    echo "Usage: $0 OPER(status|start|stop|forcestop|restart|state|log|deleteStatusFile|clean|index) [SOLR_URL]"
}

get_pid ()
{
    PID=`ps -ef | grep "$CRAWL_CMD" |grep -v grep| awk '{print $2}'`
}

check_status ()
{
    get_pid
    if [ "$PID"X = "X" ]; then
        return 1
    else
        return 0
    fi
}
print_status ()
{
    if check_status; then
        echo [`date +%"Y-%m-%d %H:%M:%S"`][$NUTCH_HOME] The program "(pid $PID)" is running...
        return 0
    else
        # 判断状态文件是否存在
        for((i=0;i < 10;i++))
        do
            if [ -f "$STATUS_FILE" ]; then
                if check_status; then
                    echo [`date +%"Y-%m-%d %H:%M:%S"`][$NUTCH_HOME] The program "(pid $PID)" is running...
                    return 0
                else
                    echo -n "."
                    sleep 1
                fi
            else
                break
            fi
        done
        echo [`date +%"Y-%m-%d %H:%M:%S"`][$NUTCH_HOME] The program is not running!
        return 1
    fi
}

kill_program ()
{
    FORCE=$1
    if check_status; then
        PIDS=$PID
        if [ ! "$FORCE" == "" ];then
            PIDS=`ps -le | grep " $PID " | grep -v grep | awk '{print  $4}'`
        fi
        echo "[$NUTCH_HOME] Will kill [$PIDS]"
        kill `ps -le | grep " $PIDS " | grep -v grep | awk '{print  $4}'`
    else
        echo [$NUTCH_HOME] Program is not running!
    fi
    if [ -f "$STATUS_FILE" ]; then
        rm -f "$STATUS_FILE"
    fi
    
    # 设置结束标志以便统计程序自行终止

    MY_LOG_FILE=${LOG_FILE}
    if [ -f $MY_LOG_FILE ]; then
        if [ ! -f $MY_LOG_FILE.STOP ]; then
            touch $MY_LOG_FILE.STOP
        fi
    fi
    #update_crawl_status 3
}

start_program ()
{
    echo "[`date +%"Y-%m-%d %H:%M:%S"`] [${NUTCH_HOME}] Start..."
    cd ${NUTCH_HOME}

    # 判断爬虫进程是否存在。如果存在则不启动
    if check_status; then
        return 1
    fi

    MY_LOG_FILE=${LOG_FILE}
    
    SQL="select STATUS_ID from ${db_table_crawl_log} where CRAWL_CODE='${CRAWL_CODE}' and MATCHINE='${MATCHINE}'"
    tmpValue=`$MYSQL_CMD "$SQL" | tail -n 1`
    if [ "$tmpValue" = "" ]; then
        # 不存在，或已完成，则新建一个
        SQL="insert into ${db_table_crawl_log} (CRAWL_CODE,MATCHINE,START_TIME,UPDATE_TIME) values ('${CRAWL_CODE}','${MATCHINE}',now(),now())"
        execute_query "$SQL"
        SQL="select STATUS_ID from ${db_table_crawl_log} where CRAWL_CODE='${CRAWL_CODE}' and MATCHINE='${MATCHINE}'"
        STATUS_ID=`$MYSQL_CMD "$SQL"  | tail -n 1`
    else
        # 存在，则将数据插入到历史表
        STATUS_ID=$tmpValue
        SQL="insert into ${db_table_crawl_log}_HIS (STATUS_ID,START_TIME,UPDATE_TIME,STATUS,MSG,ERRORS,IN_TIME) select STATUS_ID,START_TIME,UPDATE_TIME,CASE STATUS WHEN 0 THEN 3 ELSE STATUS END,MSG,ERRORS,now() from ${db_table_crawl_log} where STATUS_ID=${STATUS_ID} AND STATUS != 9"
        execute_query "$SQL"
        SQL="update ${db_table_crawl_log} set START_TIME=now(),UPDATE_TIME=now(),MSG='',STATUS=9 where STATUS_ID=${STATUS_ID}"
        execute_query "$SQL"
    fi
    
    # 清除可能存在的lock文件
    if [ -d $CRAWL_PATH ]; then
        find $CRAWL_PATH -type f -name ".locked" -print0 | xargs -0 rm -f
        #find $CRAWL_PATH -name ".locked" -exec rm -f {} \\;
    fi
    # 初始化
        
    clean
    
    if [ ! -e "$CRAWL_PATH" ];then
        mkdir "$CRAWL_PATH"
    fi
    if [ ! -e "$LOG_DIR" ];then
        mkdir "$LOG_DIR"
    fi
    
    update_crawl_status 0
    # 启动监控
    #run_state $MY_LOG_FILE > $STATE_FILE 2>&1 &
    echo $MY_LOG_FILE>$STATUS_FILE
    #启动爬虫
    echo [`date +%"Y-%m-%d %H:%M:%S"`][$NUTCH_HOME]========Start crawl... > $MY_LOG_FILE
    # sh $CRAWL_CMD $((DEPTH-1)) >> $MY_LOG_FILE 2>&1
    sh $CRAWL_CMD $DEPTH >> $MY_LOG_FILE 2>&1
    echo $? > $MY_LOG_FILE.STOP
    echo [`date +%"Y-%m-%d %H:%M:%S"`][$NUTCH_HOME]========Finish crawl. >> $MY_LOG_FILE
    sleep 15
    rm -f $STATUS_FILE
}

split_logfile ()
{
    if [ -f "$LOG_FILE" ]; then
        mv "$LOG_FILE" "$LOG_FILE".`date +%Y%m%d%H%M%S`
    fi
    if [ -f "$STATE_FILE" ]; then
        mv "$STATE_FILE" "$STATE_FILE".`date +%Y%m%d%H%M%S`
    fi
}
update_crawl_status ()
{
    STATUS=$1
    if [ "$STATUS_ID" != "" ]; then
        execute_query "update ${db_table_crawl_log} set UPDATE_TIME=now(),STATUS=$STATUS where STATUS_ID=${STATUS_ID}"
    fi

}
update_crawl_status_with_error ()
{
    STATUS=$1
    LOG_FILE=$2
    if [ "$STATUS_ID" != "" ]; then
        # 从日志结尾获取错误信息
        ERRORS=`tail -n20 "$LOG_DIR/$NUTCH_LOGFILE"`
        execute_query "update ${db_table_crawl_log} set UPDATE_TIME=now(),STATUS=$STATUS,ERRORS=right($ERRORS,5000) where STATUS_ID=${STATUS_ID}"
    fi
}
update_crawl_msg ()
{
    MSG=$1
    STATUS=$2
    if [ "$STATUS_ID" = "" ]; then
        SQL="select STATUS_ID from ${db_table_crawl_log} where CRAWL_CODE='${CRAWL_CODE}' and MATCHINE='${MATCHINE}'"
        tmpValue=`$MYSQL_CMD "$SQL" | tail -n 1`
        if [ "$tmpValue" != "" ]; then
            STATUS_ID=$tmpValue
        fi
    fi
    if [ "$STATUS_ID" != "" ]; then
        if [ "$STATUS" != "" ]; then
            execute_query "update ${db_table_crawl_log} set UPDATE_TIME=now(),MSG='$MSG',STATUS=$STATUS where STATUS_ID=${STATUS_ID}"
        else
            execute_query "update ${db_table_crawl_log} set UPDATE_TIME=now(),MSG='$MSG' where STATUS_ID=${STATUS_ID}"
        fi
    fi
}
do_state()
{
    FLAG=$1
    MY_LOG_FILE=$2
    DONOT_UPDATE=$3
    TMP_DATE=`date +"%Y-%m-%d %H:%M:%S"`
    
    MSG="[$FLAG]"
    
    # 获取进行到哪个深度了
    CURRENT_DEPTH=`grep "Generator: starting at" $MY_LOG_FILE | wc -l`
    MSG="[DEPTH:$CURRENT_DEPTH/$DEPTH]$MSG"
    FETCH_TOTAL=`grep "^fetching" ${MY_LOG_FILE} |wc -l`
    FETCH_FAIL_COUNT=`grep "^fetch of" ${MY_LOG_FILE} |wc -l`
    FETCH_SUCCESS_COUNT=$((FETCH_TOTAL - FETCH_FAIL_COUNT))
    #MSG="$MSG Fetch:{Total:$FETCH_TOTAL, Success:$FETCH_SUCCESS_COUNT, Fail:$FETCH_FAIL_COUNT}"
    MSG="$MSG Fetch:{Total:$FETCH_TOTAL, Fail:$FETCH_FAIL_COUNT}"

    PARSE_SUCCESS_COUNT=`grep "^Parsed" ${MY_LOG_FILE} |wc -l`
    PARSE_FAIL_COUNT=`grep "^Error parsing" ${MY_LOG_FILE} |wc -l`
    PARSE_TOTAL=$((PARSE_SUCCESS_COUNT + PARSE_FAIL_COUNT))
    #MSG="$MSG, Parse:{Total:$PARSE_TOTAL, Success:$PARSE_SUCCESS_COUNT, Fail:$PARSE_FAIL_COUNT}"
    MSG="$MSG, Parse:{Total:$PARSE_TOTAL, Fail:$PARSE_FAIL_COUNT}"

    echo "[$TMP_DATE][$NUTCH_HOME] $MSG"
    
    #更新爬虫状态信息
    if [ "$DONOT_UPDATE" = "" ];then
        update_crawl_msg "$MSG"
    fi
}
print_state ()
{
    MY_LOG_FILE=${LOG_FILE}
    o=0
    while(( o < 1))
    do
        if [ ! -f $STATUS_FILE ]; then
            # 等待
            for ((i=0;i<10;i++))
            do
                if [ -f $STATUS_FILE ]; then
                    break
                else
                    echo -n "."
                    sleep 1
                fi
            done
            echo "."
            if [ ! -f $STATUS_FILE ]; then
                if [ -f $MY_LOG_FILE ]; then
                    do_state "Finished" "$MY_LOG_FILE" "Donot update"
                fi
                break;
            fi
        fi
        if [ -f $MY_LOG_FILE ]; then
            if [ ! -f $MY_LOG_FILE.STOP ]; then
                echo [`date +%"Y-%m-%d %H:%M:%S"`][$NUTCH_HOME] Begin state
                run_state $MY_LOG_FILE
            fi
        fi
        echo [`date +%"Y-%m-%d %H:%M:%S"`][$NUTCH_HOME] Finished.
        sleep 10
        echo [`date +%"Y-%m-%d %H:%M:%S"`][$NUTCH_HOME] Next...
    done
}
run_state ()
{
    MY_LOG_FILE=$1
    k=0
    #FLAGS_STR="Injector Generator Fetcher ParseSegment CrawlDb LinkDb Deduplication Indexer CleaningJob"
    FLAGS_STR="Injector Generator Fetcher ParseSegment CrawlDb LinkDb Indexer CleaningJob"
    FLAGS=( $FLAGS_STR )
    FLAGS_SIZE=${#FLAGS[@]}
    sleep 5
    NOW=`date +%s`
    while(($k<1))
    do
        LATEST_FLAT=`grep elapsed $MY_LOG_FILE | tail -n 1 | cut -d ":" -f1 | cut -d " " -f1`
        for((i=0;i < $FLAGS_SIZE;))
        do
            # 判断程序是否已经退出
            if [ -f $MY_LOG_FILE.STOP ]; then
                k=1
                EXIT_CODE=`tail -n 1 $MY_LOG_FILE.STOP`
                if [ "$EXIT_CODE" = "0" ]; then
                    # 正常
                    do_state "Finished" "$MY_LOG_FILE"
                    update_crawl_status 1
                else
                    do_state "Finished" "$MY_LOG_FILE"
                    update_crawl_status_with_error 2 "$MY_LOG_FILE"
                fi
                echo [`date +%"Y-%m-%d %H:%M:%S"`][$NUTCH_HOME]-----------Finished.
                break
            fi
            if check_status; then
                if [ "${FLAGS[$i]}" = "$LATEST_FLAT" ]; then
                    # 找到上一个步骤
                    if [ $((i + 1)) -lt $FLAGS_SIZE ]; then
                        # 不是最后一个
                        do_state "STEP:$((i + 2))/${FLAGS_SIZE}-${FLAGS[$((i + 1))]}"  ${MY_LOG_FILE}
                        sleep 30
                        break
                    else
                        # 是最后一个
                        sleep 30
                    fi
                else
                    # 继续查找
                    i=$((i + 1))
                fi
            else
                k=1
                do_state "Finished" "$MY_LOG_FILE"
                update_crawl_status_with_error 3 "$MY_LOG_FILE"
                break
            fi
        done
    done
}
clean ()
{
    if [ -f "$LOG_FILE.STOP" ]; then
        echo "[$NUTCH_HOME] Clean $LOG_FILE.STOP"
        rm -f "$LOG_FILE.STOP"
        if [ -e "$LOG_FILE.STOP" ];then
            echo "Clean failed!"
        else
            echo "Clean success."
        fi
    fi
    if [ -e "$NUTCH_HOME/bin/.STOP" ]; then
        echo "[$NUTCH_HOME] Clean $NUTCH_HOME/bin/.STOP"
        rm -fr "$NUTCH_HOME/bin/.STOP"
        if [ -e "$NUTCH_HOME/bin/.STOP" ];then
            echo "Clean failed!"
        else
            echo "Clean success."
        fi
    fi
    if [ "$NEED_CLEAN_ALL" = "true" ]; then
        if [ -e "$CRAWL_PATH" ];then
            echo "[$NUTCH_HOME] Clean $CRAWL_PATH"
            rm -fr "$CRAWL_PATH"
            if [ -e "$CRAWL_PATH" ];then
                echo "Clean failed!"
            else
                echo "Clean success."
            fi
        fi
    elif [ "$NEED_CLEAN_ALL" = "false" ];then
        if [ -e "$CRAWL_PATH/segments" ];then
            echo "[$NUTCH_HOME] Clean $CRAWL_PATH/segments"
            rm -fr "$CRAWL_PATH/segments"
            if [ -e "$CRAWL_PATH/segments" ];then
                echo "Clean failed!"
            else
                echo "Clean success."
            fi
        fi
    fi
    
    if [ -e "$LOG_DIR" ];then
        echo "[$NUTCH_HOME] Clean $LOG_DIR"
        rm -fr "$LOG_DIR"
        if [ -e "$LOG_DIR" ];then
            echo "Clean failed!"
        else
            echo "Clean success."
        fi
    fi
    if [ -e "$STATUS_FILE" ];then
        echo "[$NUTCH_HOME] Clean $STATUS_FILE"
        rm -fr "$STATUS_FILE"
        if [ -e "$STATUS_FILE" ];then
            echo "Clean failed!"
        else
            echo "Clean success."
        fi
    fi
    
    # 更新数据库中的爬虫状态
    update_crawl_msg "" "9"
}
# 补建索引
index ()
{
    if [ -d "$CRAWL_PATH"/segments/ ];then
        SEGMENT=`ls "$CRAWL_PATH"/segments/ | sort -n | tail -n 1`
        if [ ! "$SEGMENT" = "" ];then
            $NUTCH_HOME/bin/nutch index -Dsolr.server.url=$SOLR_URL "$CRAWL_PATH"/crawldb -linkdb "$CRAWL_PATH"/linkdb "$CRAWL_PATH"/segments/$SEGMENT
        fi
    fi
}
##########################################################
if [ "$OPER"X = "X" ]; then
    print_usage
    exit 1
fi


case "$OPER" in
    start)
        echo  "[$NUTCH_HOME] Starting program..."

        if check_status; then
            echo "[$NUTCH_HOME] The program (pid $PID) is running..."
            exit 0
        fi
        split_logfile
        if [ ! -e ${LOG_DIR} ];then
            mkdir -p ${LOG_DIR}
        fi
        start_program
        ;;
    stop)
        echo "[$NUTCH_HOME] Stopping program:"
        kill_program
        for i in $(seq 100) ; do
            if check_status > /dev/null; then
                echo -n '.'
                sleep 1
            else
                break
            fi
        done
        if check_status > /dev/null; then
            echo "[$NUTCH_HOME] Warning - program did not exit in a timely manner"
        else
            echo "[$NUTCH_HOME] Done."
        fi
        ;;
    forcestop)
        echo "[$NUTCH_HOME] Force stopping program:"
        kill_program force
        for i in $(seq 100) ; do
            if check_status > /dev/null; then
                echo -n '.'
                sleep 1
            else
                break
            fi
        done
        if check_status > /dev/null; then
            echo '[$NUTCH_HOME] Warning - program did not exit in a timely manner'
        else
            echo '[$NUTCH_HOME] Done.'
        fi
        ;;
    status)
        get_pid
        print_status
        ;;
    state)
        print_state
        ;;
    log)
        tail -fn99 $LOG_FILE
        ;;
    restart)
        sh $0 stop  "$SOLR_URL"
        sh $0 start "$SOLR_URL"
        ;;
    deleteStatusFile)
        if [ -f "$STATUS_FILE" ]; then
            rm -f "$STATUS_FILE"
        fi
        ;;
    clean)
        clean
        ;;
    index)
        index
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
