# Prerequisite
Require sysbench installed

# Functions
1. warm_up.sh
load data into bufferpool before run sysbench

2. run_sysbench.sh
- This script help to format the sysbench cumulative result into csv format
- Run with a group of threads
- Run 3 times for each --threads option by default
- Sleep 60s for each round

# Compatability
Tested with sysbench 1.0.20

# Usage
0. warm up
```
./warm_up.sh -uroot -pxxx -h 10.10.36.92 -P 6606 -D sysbench -n 60

Usage: ./warm_up.sh [options]
-u : user name
-p : password
-h : MySQL server host
-P : MySQL server port
-D : database name
-n : number of tables to warm up
```

1. Config first
```
threads=(1 4 8 16 32 64 128 256 512 1024)          # --threads option will be overwritten here if you pass as parameter
round=3                                            # the number of rounds for each thread
sleep=60                                           # seconds of sleep between each round
```
2. Run
```
./run_sysbench.sh sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=x.x.x.x --mysql-port=3306 --mysql-user=sysbench --mysql-password=xxxx --mysql-db=sysbench --tables=60 --table-size=40000000  --events=0  --point_selects=4 --distinct_ranges=0 --delete_inserts=0 --index_updates=1 --non_index_updates=0 --order_ranges=0 --range_selects=off --simple_ranges=0 --skip_trx=on --db-ps-mode=disable --report-interval=0 --rand-type=special --percentile=99 --max-requests=0 --time=1800 --threads=2 run
```
