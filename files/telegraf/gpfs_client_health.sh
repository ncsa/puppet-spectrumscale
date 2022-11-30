#!/bin/bash
# This file is managed by Puppet - Changes may be overwritten

# Original script is maintained at:
# https://git.ncsa.illinois.edu/ici-monitoring/ici-developed-checks/-/blob/main/spectrum_scale_client/ss_health.sh

## Check if Node even uses GPFS
if [ -d /usr/lpp/mmfs/bin ]; then

  source /etc/telegraf/scripts/gpfs/gpfs_client_health_config

  ## Waiters
  wtemp=$(mktemp /tmp/waiter.XXXXX)
  sudo /usr/lpp/mmfs/bin/mmdiag --waiters | grep -v = | tail -n +2 > ${wtemp}
  count_w=$(cat ${wtemp} | wc -l)
  if [ $count_w -ne 0 ]; then
    longest_w=$(head -1 ${wtemp} | cut -d',' -f 1 | sed 's/.*[Ww]aiting //;s/ sec.*//')
  else
    longest_w=0.0
  fi
  rm -rf ${wtemp}

  ## mmfsd Info
  pid=$(ps -ef | grep mmfsd | grep lpp | awk '{print $2}')
  read -r cpu_usage mem_usage <<< $(top -b -n 2 -p $pid | grep mmfsd | tail -1 | awk '{print $9,$10}')

  if [ -z $cpu_usage ]; then
    cpu_usage=0
    m_count=0
  fi
  if [ -z $mem_usage ]; then
    mem_usage=0
    m_count=0
  fi

  echo "waitercount,type=client count=$count_w"
  echo "longestwaiter,type=client length=$longest_w"
  echo "daemoncpu,type=client usage=$cpu_usage"
  echo "daemonmem,type=client usage=$mem_usage"

  ## FS Responsive Test ##
  tfile1=$(mktemp /tmp/ls.XXXXXX)
  tfile2=$(mktemp /tmp/stat.XXXXXXX)

  for p in ${paths[@]}
  do
    { time ls ${p} ; } 2> ${tfile1} 1> /dev/null
    min=$(cat ${tfile1} | grep real | awk '{print $2}' | cut -d'm' -f 1)
    sec=$(cat ${tfile1} | grep real | awk '{print $2}' | cut -d'm' -f 2 | cut -d's' -f 1)
    time=$( bc -l <<<"60*$min + $sec" )
    echo fs_ls_time,path=${p} duration=${time}
  done

  for f in ${files[@]}
  do
    { time stat ${f} ; } 2> ${tfile2} 1> /dev/null
    min=$(cat ${tfile2} | grep real | awk '{print $2}' | cut -d'm' -f 1)
    sec=$(cat ${tfile2} | grep real | awk '{print $2}' | cut -d'm' -f 2 | cut -d's' -f 1)
    time=$( bc -l <<<"60*$min + $sec" )
    echo fs_stat_time,path=${f} duration=${time}
  done

  rm -rf $tfile1
  rm -rf $tfile2

  ### Get File System List to Check
  #all_fs_list=($(cat /etc/fstab | awk '$3 == "gpfs" { print $1 }'))
  #no_mount_list=($(ls /var/mmfs/etc/ | grep -i ignoreAnyMount | cut -d'.' -f 2))
  #fs_list=()
  #for a in ${all_fs_list[@]}
  #do
  #  if [[ ! " ${no_mount_list[@]} " =~ " ${a} " ]]; then
  #    fs_list+=(${a})
  #  fi
  #done

  ## Check the list
  for f in ${fs[@]}
  do
    check=$(grep $f /proc/mounts | grep gpfs)
    if [ -n "$check" ]; then
      #It's in /proc/mounts
      proc_check=0
    else
      proc_check=1
    fi
    mpoint=$(grep gpfs /etc/fstab | grep -v bind | grep ${f} | awk '{print $2}')
    stat=$(stat ${mpoint}/.SETcheck)
    if [ -n "$stat" ]; then
      #We can stat a file
      stat_check=0
    else
      stat_check=1
    fi
    if [ $proc_check -eq 0 ] && [ $stat_check -eq 0 ]; then
      #All is healthy
      echo "mountcheck,fs=${f} presence=1"
   else
      echo "mountcheck,fs=${f} presence=0"
    fi
  done

  ### mmfsd memory info
  read -r heap pool_1 pool_2 pool_3 <<< "$(sudo /usr/lpp/mmfs/bin/mmdiag --memory | grep bytes | grep -v committed | sed 's/[^0-9]*//g' | xargs)"
  echo "mmfsd_memory heap=${heap},pool_1=${pool_1},pool_2=${pool_2},pool_3=${pool_3}"

  ## mmdiag stats
  read -r of_inuse of_free of_mem stat_inuse stat_dirs stat_free stat_mem <<< "$(sudo /usr/lpp/mmfs/bin/mmdiag --stats -Y | grep 'openFile\|statCache' | grep 'inUse\|dirs\|free\|memory' | cut -d':' -f 10 | xargs)"
  echo "mmdiag_stats file_cache_used=${of_inuse},file_cache_free=${of_free},file_cache_memory=${of_mem},stat_cache_used=${stat_inuse},stat_cache_dirs=${stat_dirs},stat_cache_free=${stat_free},stat_cache_memory=${stat_mem}"

else
  :
fi
