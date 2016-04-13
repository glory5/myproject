#!/bin/bash
filePath='/home/kafka/kafka_new.csv'
#/var/log/upstart/SCBMemoryStatus.csv
 
if  test -s "$filePath"
then
        echo "Writing Memory Stats to file."
else 		     echo	"Date ,Kafka_Serv_PID ,Kafka_Serv_CPU ,Kafka_Serv_RSSMemory ,Kafka_Serv_VirtualMemory ,Kafka_Serv_RSSMemory_Percent ,Kafka_serv_Heap_USED, Kafka_serv_Heap_Total,Kafka_Serv_DiskRead ,Kafka_Serv_DiskWrite,Consumer1_PID ,Consumer1_CPU ,Consumer1_RSSMemory ,Consumer1_VirtualMemory ,Consumer1_RSSMemory_Percent ,Consumer1_Heap_USED, Consumer1_Heap_Total,Consumer1_DiskRead ,Consumer1_DiskWrite,Consumer2_PID ,Consumer2_CPU ,Consumer2_RSSMemory ,Consumer2_VirtualMemory ,Consumer2_RSSMemory_Percent ,Consumer2_Heap_USED, Comsumer2_Heap_Total,Consumer2_DiskRead ,Consumer2_DiskWrite,ZOOK_PID ,ZOOK_CPU ,ZOOK_RSSMemory ,ZOOK_VirtualMemory ,ZOOK_RSSMemory_Percent ,ZOOK_Heap_USED, ZOOK_Heap_Total,ZOOK_DiskRead ,ZOOK_DiskWrite,us_CPU ,sy_CPU,ni_CPU,idle_CPU,wa_CPU,hi_CPU,si_CPU,st_CPU,Machine_TotalMemUsage ,Machine_ActualMemUsage ,Machine_TotalMem ,RootPartition_DiskUsage, ExportPartition_DiskUsage, ExportPartition_DiskUsage_percent,Machine_DiskRead, Machine_DiskWrite" >> $filePath
fi


export PGPASSWORD=postgres
 
while [ 1 ]; do
    sleep 5

#echo "$(date --rfc-3339=seconds)"
Date=$(date)
TotalMemory=$(free -m | awk '/^Mem:/{print $2}')
UsedMem=$(free -m | awk '/^Mem:/{print $3}')
PercMem=$(echo "scale=5; ($UsedMem * 100) / $TotalMemory" | bc -l | awk '{printf "%f", $0}')
diskSpaceUsed_per=$(/bin/df | grep '/export$' | awk '{print $4}')
diskSpaceUsed_t=$(/bin/df -m | grep '/export$' | awk '{print $2}')
diskSpaceUsed=${diskSpaceUsed_per%?}
root_diskSpaceUsed_per=$(/bin/df | grep '/$' | awk '{print $4}')
root_diskSpaceUsed_t=$(/bin/df -m | grep '/$' | awk '{print $2}')
Actual_UsedMemory=$(free | awk 'FNR == 3 {print $3/1024}')
Actual_UsedMemoryPerc=$(free | awk 'FNR == 3 {print $3/($3+$4)*100}')

#CPU

CPU=$( top -b -n1 | grep "Cpu(s)")

CPU0=$(echo $CPU | awk '{print $2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17}')

#DISK
DISK=$(/usr/sbin/iotop -b -n1 | grep "Total ")
DISKREAD=$(echo $DISK | awk '{print $4}')
DISKWRITE=$(echo $DISK | awk '{print $10}')

  ###Server Stats        
#Calculating stats for monitoring module - Start
PIDS_s=$(ps ax | grep config/server.properties |grep -v grep | awk '{print $1}')
#ps ax -o pid,rssize,vsize,pcpu,command | grep kafka.Kafka config/server.properties |awk '{print $1}')
mm_pid1_s=$(echo $PIDS_s |awk '{print $1}')
  
 
#Calculating data for monitoring module End --
 
 
RSS_MM1=$(ps ax -o pid,rssize,vsize,pcpu,command | grep $mm_pid1_s|grep -v grep |awk '{print $2}')
RSS_MM_s=$(echo "$RSS_MM1/1024"| bc -l | awk '{printf "%f", $0}')
VM_MM1=$(ps ax -o pid,rssize,vsize,pcpu,command |grep $mm_pid1_s |grep -v grep|awk '{print $3}')
VM_MM_s=$(echo "$VM_MM1/1024"| bc -l | awk '{printf "%f", $0}')
CPU_P_s=$(ps ax -o pid,rssize,vsize,pcpu,command | grep $mm_pid1_s|grep -v grep|awk '{print $4}')

 
 # Memory Usage
MEM_PR_s=$(ps aux | grep kafka_2.11-0.9.0.0/bin/ |grep $mm_pid1_s |grep -v grep |awk '{print $4}')

# Calculating IO Usage
#IOU=$( iotop -p $mm_pid1 | grep "zookeeper")

IO_R_s=$( pidstat -dl | grep $mm_pid1_s |grep -v grep | awk '{print $4 }')
IO_W_s=$( pidstat -dl | grep $mm_pid1_s |grep -v grep | awk '{print $5 }') 
## HEAP

heap_total_s=$(jstat -gc $mm_pid1_s |grep -v C | awk '{print $1+ $2 + $5 + $7}')
heap_used_s=$(jstat -gc $mm_pid1_s |grep -v U | awk '{print $3+ $4 + $6 + $8}')
 

	##Consumer         
#Calculating stats for monitoring module - Start
#PIDS_c=$(ps ax -o pid,rssize,vsize,pcpu,command | grep kafka.tools.ConsoleConsumer|grep -v grep  |awk '{print $1}')
PIDS_c1=$(echo $(ps ax -o pid,rssize,vsize,pcpu,command | grep kafka.tools.ConsoleConsumer|grep -v grep  |awk '{print $1}')| awk '{print $1}')
PIDS_c2=$(echo $(ps ax -o pid,rssize,vsize,pcpu,command | grep kafka.tools.ConsoleConsumer|grep -v grep  |awk '{print $1}')| awk '{print $2}')
#PIDS_c1=$(echo $PIDS_c |awk '{print $1}')

 
#Calculating data for monitoring module End --
 
 
RSS_MM_1=$(echo $(ps ax -o pid,rssize,vsize,pcpu,command |grep  kafka.tools.ConsoleConsumer|grep -v grep  |awk '{print $2}')|awk '{print $1}')
RSS_MM_1=$(echo $(ps ax -o pid,rssize,vsize,pcpu,command |grep  kafka.tools.ConsoleConsumer|grep -v grep  |awk '{print $2}')|awk '{print $2}')

RSS_MM_c1=$(echo "$RSS_MM1/1024"| bc -l | awk '{printf "%f", $0}')
RSS_MM_c2=$(echo "$RSS_MM1/1024"| bc -l | awk '{printf "%f", $0}')

VM_MM_1=$(echo $(ps ax -o pid,rssize,vsize,pcpu,command |grep  kafka.tools.ConsoleConsumer|grep -v grep  |awk '{print $3}')|awk '{print $1}')
VM_MM_2=$(echo $(ps ax -o pid,rssize,vsize,pcpu,command |grep  kafka.tools.ConsoleConsumer|grep -v grep  |awk '{print $3}')|awk '{print $1}')
VM_MM_c1=$(echo "$VM_MM1/1024"| bc -l | awk '{printf "%f", $0}')
VM_MM_c2=$(echo "$VM_MM1/1024"| bc -l | awk '{printf "%f", $0}')

CPU_P_c1=$(echo $(ps ax -o pid,rssize,vsize,pcpu,command |grep  kafka.tools.ConsoleConsumer|grep -v grep  |awk '{print $4}')|awk '{print $1}')

CPU_P_c2=$(echo $(ps ax -o pid,rssize,vsize,pcpu,command |grep  kafka.tools.ConsoleConsumer|grep -v grep  |awk '{print $4}')|awk '{print $2}')

MEM_PR_c1=$(ps aux | grep kafka.tools.ConsoleConsumer |grep $PIDS_c1 |grep -v grep |awk '{print $4}')

MEM_PR_c2=$(ps aux | grep kafka.tools.ConsoleConsumer |grep $PIDS_c2 |grep -v grep |awk '{print $4}')

## HEAP

heap_total_c1=$(jstat -gc $PIDS_c1 |grep -v C | awk '{print $1+ $2 + $5 + $7}')
heap_used_c1=$(jstat -gc $PIDS_c1|grep -v U | awk '{print $3+ $4 + $6 + $8}')

## HEAP

heap_total_c2=$(jstat -gc $PIDS_c2 |grep -v C | awk '{print $1+ $2 + $5 + $7}')
heap_used_c2=$(jstat -gc $PIDS_c2 |grep -v U | awk '{print $3+ $4 + $6 + $8}')

# Calculating IO Usage
#IOU=$( iotop -p $mm_pid1 | grep "zookeeper")

IO_R_c1=$( pidstat -dl | grep $PIDS_c1 | awk '{print $4 }')
IO_W_c1=$( pidstat -dl | grep $PIDS_c1 | awk '{print $5 }') 
           

IO_R_c2=$( pidstat -dl | grep $PIDS_c2 | awk '{print $4 }')
IO_W_c2=$( pidstat -dl | grep $PIDS_c2 | awk '{print $5 }') 

	##Zookeper stats
#Calculating stats for monitoring module - Start
PIDS_z=$(ps ax -o pid,rssize,vsize,pcpu,command |grep zookeeper/conf|grep -v grep  |awk '{print $1}')
mm_pid1_z=$(echo $PIDS_z |awk '{print $1}')
 
 
#Calculating data for monitoring module End --
 
 
RSS_MM1=$(ps ax -o pid,rssize,vsize,pcpu,command |grep zookeeper/conf |grep -v grep |awk '{print $2}')
RSS_MM_z=$(echo "$RSS_MM1/1024"| bc -l | awk '{printf "%f", $0}')
VM_MM1=$(ps ax -o pid,rssize,vsize,pcpu,command | grep zookeeper/conf |grep -v grep |awk '{print $3}')
VM_MM_z=$(echo "$VM_MM1/1024"| bc -l | awk '{printf "%f", $0}')
CPU_P_z=$(ps ax -o pid,rssize,vsize,pcpu,command | grep zookeeper/conf |grep -v grep |awk '{print $4}')

 # Memory Usage
MEM_PR_z=$(ps aux |grep zookeeper/conf |grep $mm_pid1_z |grep -v grep |awk '{print $4}')
## HEAP

heap_total_z=$(jstat -gc $mm_pid1_z |grep -v C | awk '{print $1+ $2 + $5 + $7}')
heap_used_Z=$(jstat -gc $mm_pid1_z |grep -v U | awk '{print $3+ $4 + $6 + $8}')
# Calculating IO Usage
#IOU=$( iotop -p $mm_pid1 | grep "zookeeper")

IO_R_z=$( pidstat -dl | grep $mm_pid1_z|grep -v grep  | awk '{print $4 }')
IO_W_z=$( pidstat -dl | grep $mm_pid1_z|grep -v grep  | awk '{print $5 }')
#echo "$Date, $mm_pid1, $mm_pid2, $mm_pid3, $mm_pid4, $mm_pid5, $mm_pid6, $mm_pid7, $mm_pid8, $mm_pid9, $mm_pid10, $mm_pid11, $mm_pid12, $cppPid, $cpp_vm"  
echo "$Date, $mm_pid1_s, $CPU_P_s, $RSS_MM_s,$VM_MM_s,$MEM_PR_s,$heap_used_s,$heap_total_s,$IO_R_s, $IO_W_s,$PIDS_c1, $CPU_P_c1,$RSS_MM_c1,$VM_MM_c1,$MEM_PR_c1,$heap_used_c1,$heap_total_c1, $IO_R_c1, $IO_W_c1,$PIDS_c2, $CPU_P_c2,$RSS_MM_c2,$VM_MM_c2,$MEM_PR_c2,$heap_used_c2,$heap_total_c2, $IO_R_c2, $IO_W_c2,$mm_pid1_z, $CPU_P_z, $RSS_MM_z,$VM_MM_z,$MEM_PR_z,$heap_used_z,$heap_total_z, $IO_R_z, $IO_W_z,$CPU0,$UsedMem,$Actual_UsedMemory,$TotalMemory, $root_diskSpaceUsed_t, $diskSpaceUsed_t,$diskSpaceUsed,$DISKREAD,$DISKWRITE" >> $filePath
done
