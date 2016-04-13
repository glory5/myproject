#!/bin/bash
filePath='/home/kafka/Logstash_new.csv'
#/var/log/upstart/SCBMemoryStatus.csv
 
if  test -s "$filePath"
then
        echo "Writing Memory Stats to file."
else
  echo "Date , Logstash_PID ,Logstash_CPU ,Logstash_RSSMemory ,Logstash_VirtualMemory ,Logstash_RSSMemory_Percent ,Logstash_Heap_USED,Logstash_ Heap_Total,Logstash_DiskRead ,Logstash_DiskWrite, us_CPU , sy_CPU, ni_CPU,idle_CPU,wa_CPU,hi_CPU,si_CPU,st_CPU, Machine_TotalMemUsage ,Machine_ActualMemUsage ,Machine_TotalMem ,Machine_DiskUsage, Machine_DiskUsage_percent,Machine_DiskRead, Machine_DiskWrite
" >> $filePath
fi

export PGPASSWORD=postgres
 
while [ 1 ]; do
    sleep 5
 
#echo "$(date --rfc-3339=seconds)"
Date=$(date)
TotalMemory=$(free -m | awk '/^Mem:/{print $2}')
UsedMem=$(free -m | awk '/^Mem:/{print $3}')
PercMem=$(echo "scale=5; ($UsedMem * 100) / $TotalMemory" | bc -l | awk '{printf "%f", $0}')
diskSpaceUsed_per=$(/bin/df | grep '/export$' | awk '{print $5}')
diskSpaceUsed_t=$(/bin/df | grep '/export$' | awk '{print $3}')
diskSpaceUsed=${diskSpaceUsed_per%?}
Actual_UsedMemory=$(free | awk 'FNR == 3 {print $3/1024}')
Actual_UsedMemoryPerc=$(free | awk 'FNR == 3 {print $3/($3+$4)*100}')
 
           
#Calculating stats for monitoring module - Start
PIDS=$(ps ax -o pid,rssize,vsize,pcpu,command |  grep logstash-2.2.0/vendor/jruby/lib/jni | grep -v grep |awk '{print $1}')
mm_pid1=$(echo $PIDS |awk '{print $1}')
 
 
sfile_mm_pid1=/proc/$mm_pid1/stat
#if [ ! -r $sfile_mm_pid1 ]; then echo "pid $mm_pid1 not found in /proc" ; exit 1; fi
proctime_mm_pid1=$(cat $sfile_mm_pid1|awk '{print $14}')
totaltime_mm_pid1=$(grep '^cpu ' /proc/stat |awk '{sum_mm_pid1=$2+$3+$4+$5+$6+$7+$8+$9+$10; print sum_mm_pid1}')
 
 
#Calculating data for monitoring module End --
 
 
RSS_MM1=$(ps ax -o pid,rssize,vsize,pcpu,command |  grep logstash-2.2.0/vendor/jruby/lib/jni | grep -v grep |awk '{print $2}')
RSS_MM=$(echo "$RSS_MM1/1024"| bc -l | awk '{printf "%f", $0}')
VM_MM1=$(ps ax -o pid,rssize,vsize,pcpu,command | grep logstash-2.2.0/vendor/jruby/lib/jni | grep -v grep |awk '{print $3}')
VM_MM=$(echo "$VM_MM1/1024"| bc -l | awk '{printf "%f", $0}')
CPU_P=$(ps ax -o pid,rssize,vsize,pcpu,command |  grep logstash-2.2.0/vendor/jruby/lib/jni | grep -v grep  |awk '{print $4}')
#Calculating RSS memory
mm_pm1=$(echo $RSS_MM |awk '{print $1}')
 
 
#Calculating Virtual memory
mm_vm1=$(echo $VM_MM |awk '{print $1}')
 
 
#Calculating Calculating CPU Usage
    prevproctime_mm_pid1=$proctime_mm_pid1
    prevtotaltime_mm_pid1=$totaltime_mm_pid1
    proctime_mm_pid1=$(cat $sfile_mm_pid1|awk '{print $14}')
    totaltime_mm_pid1=$(grep '^cpu ' /proc/stat |awk '{sum_mm_pid1=$2+$3+$4+$5+$6+$7+$8+$9+$10; print sum_mm_pid1}')
    ratio_mm_pid1=$(echo "scale=2;($proctime_mm_pid1 - $prevproctime_mm_pid1) / ($totaltime_mm_pid1 - $prevtotaltime_mm_pid1)"|bc -l)
            mm_pid1CPU=$(echo "$ratio_mm_pid1 * 100" | bc -l)
            mm_pid1StatCPU=$mm_pid1CPU
    #echo "$(date --rfc-3339=seconds),     $(echo "$ratio_mm_pid1*100"|bc -l)"
 
mmStatPM1=$(echo "scale=5; $mm_pm1/1024" | bc -l | awk '{printf "%f", $0}')
mm_vm1=$(echo $VM_MM |awk '{print $1}')
#echo "mm_pid1StatCPU=$mm_pid1StatCPU, mmStatPM1=$mmStatPM1, mm_vm1=$mm_vm1 "
  
CPU=$( top -b -n1 | grep "Cpu(s)")

CPU0=$(echo $CPU | awk '{print $2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17}')

 # Memory Usage
MEM_PR=$(ps aux | grep logstash-2.2.0/vendor/jruby/lib/jni | grep -v grep |grep $mm_pid1 |awk '{print $4}')

## HEAP

heap_total=$(jstat -gc $mm_pid1 |grep -v C | awk '{print $1+ $2 + $5 + $7}')
heap_used=$(jstat -gc $mm_pid1 |grep -v U | awk '{print $3+ $4 + $6 + $8}')

# Calculating IO Usage
#IOU=$( iotop -p $mm_pid1 | grep "zookeeper")
DISK=$(/usr/sbin/iotop -b -n1 | grep "Total ")
DISKREAD=$(echo $DISK | awk '{print $4}')
DISKWRITE=$(echo $DISK | awk '{print $10}')

IO_R=$( pidstat -d -p $mm_pid1 | grep $mm_pid1 | awk '{print $4 }')
IO_W=$( pidstat -d -p $mm_pid1| grep $mm_pid1  | awk '{print $5 }')
#echo "$Date, $mm_pid1, $mm_pid2, $mm_pid3, $mm_pid4, $mm_pid5, $mm_pid6, $mm_pid7, $mm_pid8, $mm_pid9, $mm_pid10, $mm_pid11, $mm_pid12, $cppPid, $cpp_vm"  
echo "$Date, $mm_pid1, $mm_pid1StatCPU, $RSS_MM, $VM_MM, $MEM_PR,$heap_used,$heap_total,$IO_R, $IO_W, $CPU0, $UsedMem, $Actual_UsedMemory,$TotalMemory,$diskSpaceUsed_t,$diskSpaceUsed,$DISKREAD,$DISKWRITE" >> $filePath
done