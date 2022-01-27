#!/usr/bin/env bash
set -ueo pipefail
#set -x


usage()
{
  echo ""
  echo "Usage: $0 [options]
-u : user name
-p : password
-h : MySQL server host
-P : MySQL server port
-D : database name
-n : number of tables to warm up
"
  exit 1
}

while getopts ":u:p:h:P:D:n:" opt
do
  case "$opt" in
    u ) user="$OPTARG" ;;
    p ) pass="$OPTARG" ;;
    h ) host="$OPTARG" ;;
    P ) port="$OPTARG" ;;
    D ) db="$OPTARG" ;;
    n ) num="$OPTARG" ;;
    * ) usage ;;
  esac
done

if [ -z "$user" ] || [ -z "$pass" ] || [ -z "$host" ] || [ -z "$port" ] || [ -z "$db" ] || [ -z "$num" ]
then
  echo "missing parameters"
  usage
fi

conn="mysql -u $user -p$pass -h $host -P $port $db -N -s -e "

for i in $(seq 1 $num)
do
  table="sbtest$i"
  echo "warm up $table..."
  warm_up="select count(pad) from $table use index (k_$i); analyze table $table;"
  $conn "$warm_up" > /dev/null
  echo "warm up $table done."
done

echo "Completed!"
