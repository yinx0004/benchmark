#!/usr/bin/env bash
set -euo pipefail
#set -x

ROUND=3
NAME=${0##*/}
CMD=$@
DIR=$(pwd)
TIME=$(date "+%Y-%m-%d")"_"$(date "+%H-%M-%S")
LOG="${DIR}/${NAME}-${TIME}.log"
SHELL_LOCK="${DIR}/${NAME}.lock"
RESULT="${DIR}/${NAME}-${TIME}.csv"

log(){
   LOG_INFO=$@
   echo "$(date "+%Y-%m-%d") $(date "+%H:%M:%S") ${LOG_INFO}"  | tee -a  $LOG
}

usage()
{
  echo "Usage : ${NAME} full sysbench command"
  echo "Example: ${NAME} sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=x.x.x.x --mysql-port=3306 --mysql-user=sysbench --mysql-password=xxxxxxxxxx --mysql-db=sysbench --tables=60 --table-size=40000000 --events=0 --point_selects=4 --distinct_ranges=0 --delete_inserts=0 --index_updates=1 --non_index_updates=0 --order_ranges=0 --range_selects=off --simple_ranges=0 --skip_trx=on --db-ps-mode=disable --report-interval=1 --rand-type=special --percentile=99 --max-requests=0 --time=1800 --threads=128 run"
  exit 1
}

lock(){
  touch ${SHELL_LOCK}
}

unlock(){
  rm -f ${SHELL_LOCK}
}

dry_run(){
# To output the header to csv result file
  log "dry run ..."
  dry_run_cmd="${CMD} --mysql-dry-run"
  $dry_run_cmd | awk '{ sub(/^[ \t]+/, ""); gsub(/[ ]+/," "); print }' |awk -F ":" '{ \
if (match($0,/(^Number of threads)/)) print $1":"$2;
else if (match($0,/(read:)/)) print $1":"$2;
else if (match($0,/(write:)/)) print $1":"$2;
else if (match($0,/(other:)/)) print $1":"$2;
else if (match($0,/(total:)/)) print $1":"$2;
else if (match($0,/(transactions:)/)) {sub(/\(/, ""); split($2, a, " ");  print $1" per sec: "a[2];}
else if (match($0,/(queries:)/)) {sub(/\(/, ""); split($2, a, " "); print $1" per sec: "a[2];}
else if (match($0,/(ignored errors:)/)) {sub(/\(/, ""); split($2, a, " "); print $1" per sec: "a[2];}
else if (match($0,/(reconnects:)/)) {sub(/\(/, ""); split($2, a, " "); print $1" per sec: "a[2];}
else if (match($0,/(total time:)/)) print $1":"$2;
else if (match($0,/(total number of events:)/)) print $1":"$2;
else if (match($0,/(min:)/)) print "Latency "$1"(ms):"$2;
else if (match($0,/(avg:)/)) print "Latency "$1"(ms):"$2;
else if (match($0,/(max:)/)) print "Latency "$1"(ms):"$2;
else if (match($0,/(percentile:)/)) print "Latency "$1"(ms):"$2;
else if (match($0,/(sum:)/)) print "Latency "$1"(ms):"$2;
else if (match($0,/(events \(avg\/stddev\):)/)) print $1":"$2;
else if (match($0,/(execution time \(avg\/stddev\):)/)) print $1":"$2;
}' \
|  awk -F ":" '{print $1}' \
|sed  -e 's|$|,|g' |tr '\n' ' ' \
|awk '{ sub(/^[ \t]+/, ""); print }' \
| awk '{ sub(/[ \t]+$/, ""); print }' \
|awk '{sub(/,$/, ""); print}' >> $RESULT
  log "dry run done."
}

run(){
# to output the cumulative result to csv result file
  log "run ..."
  $CMD | awk '{ sub(/^[ \t]+/, ""); gsub(/[ ]+/," "); print }' |awk -F ":" '{ \
if (match($0,/(^Number of threads)/)) print $1":"$2;
else if (match($0,/(read:)/)) print $1":"$2;
else if (match($0,/(write:)/)) print $1":"$2;
else if (match($0,/(other:)/)) print $1":"$2;
else if (match($0,/(total:)/)) print $1":"$2;
else if (match($0,/(transactions:)/)) {sub(/\(/, ""); split($2, a, " ");  print $1" per sec: "a[2];}
else if (match($0,/(queries:)/)) {sub(/\(/, ""); split($2, a, " "); print $1" per sec: "a[2];}
else if (match($0,/(ignored errors:)/)) {sub(/\(/, ""); split($2, a, " "); print $1" per sec: "a[2];}
else if (match($0,/(reconnects:)/)) {sub(/\(/, ""); split($2, a, " "); print $1" per sec: "a[2];}
else if (match($0,/(total time:)/)) print $1":"$2;
else if (match($0,/(total number of events:)/)) print $1":"$2;
else if (match($0,/(min:)/)) print "Latency "$1"(ms):"$2;
else if (match($0,/(avg:)/)) print "Latency "$1"(ms):"$2;
else if (match($0,/(max:)/)) print "Latency "$1"(ms):"$2;
else if (match($0,/(percentile:)/)) print "Latency "$1"(ms):"$2;
else if (match($0,/(sum:)/)) print "Latency "$1"(ms):"$2;
else if (match($0,/(events \(avg\/stddev\):)/)) print $1":"$2;
else if (match($0,/(execution time \(avg\/stddev\):)/)) print $1":"$2;
}' \
|  awk -F ":" '{print $2}' \
|sed  -e 's|$|,|g' |tr '\n' ' ' \
|awk '{ sub(/^[ \t]+/, ""); print }' \
| awk '{ sub(/[ \t]+$/, ""); print }' \
|awk '{sub(/,$/, ""); print}' >> $RESULT
  log "run done."
}


exec(){
  if [ -f "$SHELL_LOCK" ];then
     msg="[Error] ${NAME} is running, aborted!"
     log $msg
     exit
  fi

  msg="sysbench started..."
  log $msg
  lock
  touch $RESULT
  echo $CMD >> $RESULT
  log $CMD

  dry_run

  for i in $(seq 1 $ROUND)
  do
    log "Round $i"
    run
  done

  unlock
  msg="sysbench completed! Please check the result in $RESULT"
  log $msg
}


main(){
  if [ $# -eq 0 ]
  then
          usage
  else
          exec
  fi
}


main $CMD
