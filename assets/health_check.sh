#!/bin/bash
###############################################################
# Description：SuSe health check，Include：
# 1. Memory, Disk Usage, Load, CPU
# 2. Process
# 3. Password Expiration
# 4. CPU, IO, NetWork
###############################################################

# Check status and report
check_report_log=/var/log/ha/shelllog/health_check.log
status_result=/tmp/status_result

# Configure process(es) to check
process_names=(ha_monitor ha.bin nginx unicorn_rails)

# Configure Thresholds
memory_threshold=99
swap_threshold=80
load_threshold=$(grep 'model name' /proc/cpuinfo | wc -l)
storage_threshold=80
io_threshold=80

# Configure Users to check password expiration
users=(root dmk)

cd "$(dirname $0)"
CURRENT_DIR=$(pwd)

die()
{
  echo "$*" >> $check_report_log
  exit 1
}

record_check_info()
{
  echo '------------------------------------------------------------------------------------' >> $check_report_log
  echo ${1} >> $check_report_log
  eval ${1} >> $check_report_log
}
record_alarm()
{
  echo '--------------------------------------WARNING---------------------------------------' >> $check_report_log
  echo "CRITICAL : $*" >> $check_report_log
  echo ' ' >> $check_report_log
  echo 1 > $status_result
}

prepare()
{
  # Need root
  echo "Running script with $(whoami)" >> $check_report_log
  chown dmk:dmk $check_report_log
  [ $(whoami) == root ] || die "Must be logged on as root to run this script."

  # Record time
  CHECK_DATE=$(date +%F)
  echo "Running script at $(date)" >> $check_report_log

  # Set status file as OK and log report file
  echo 0 > $status_result
  rm -f $check_report_log
}

load_check()
{
  record_check_info '/usr/bin/uptime'
  load=$(/usr/bin/uptime | awk -F',' '{print $NF}' | cut -d\. -f1)
  [ $load -lt $load_threshold ] || record_alarm "Load Average of $load exceed $load_threshold over the last 15 minutes."
}

mem_check()
{
  record_check_info '/usr/bin/free'
  memory_capacity=$(/usr/bin/free -m | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d\. -f1)
  [ $memory_capacity -lt $memory_threshold ] || record_alarm "Memory usage of $memory_capacity% exceed $memory_threshold%."
}

disk_check()
{
  record_check_info '/bin/df -TH'
  disks_capacity=$(/bin/df -h | grep -v Filesystem | awk '{print $5}' | sed -e 's/\%//g')
  for disk_capacity in ${disks_capacity[@]}; do
    [ $disk_capacity -lt $storage_threshold ] || record_alarm "Currently $disk_capacity% capacity exceed $storage_threshold%."
  done
}

io_check()
{
  record_check_info '/usr/bin/iostat -x'
  disks_io=$(iostat -dx | awk '{print $NF}' | grep -E '[0-9]{1,2}\.[0-9]{1,2}' | cut -d\. -f1)
  for disk_io in ${disks_io[@]}; do
    [ $disk_io -lt $io_threshold ] || record_alarm "Currently $disk_io% capacity exceed $io_threshold%."
  done
}

network_check()
{
  record_check_info '/sbin/ifconfig'
  packet_errors=$(ifconfig | grep -E eth* | grep packets | awk '{print $3}' | cut -d\: -f2)
  for packet_error in ${packet_errors[@]}; do
    [ $packet_error -eq 0 ] || record_alarm "RX/TX packets have errors: $packet_error."
  done
}

check_base_of_vm()
{
   load_check
   mem_check
   disk_check
   io_check
   network_check
}

check_process()
{
  for process in ${process_names[@]}; do
    process_count=$(ps ax |grep -v grep | grep -c $process)
    record_check_info "ps ax | grep -v grep | grep $process"
    [ $process_count -ne 0 ] || record_alarm "$process not running."
  done
}

check_if_passwd_expire()
{
  for user in ${users[@]}; do
    record_check_info "chage -l $user"
    password_expiration $user
  done
}

password_expiration()
{
  local user_name=$1
  current_days=$((`date --utc +%s`/86400))
  shadow_info=$(cat /etc/shadow | grep $user_name)
  IFS=':'
  read -ra shadow_info_arr <<< "$shadow_info"
  last_change_date=${shadow_info_arr[2]}
  max_date=${shadow_info_arr[4]}
  warning_date=${shadow_info_arr[5]}
  if [[ $(($last_change_date+$max_date-$warning_date-$current_days)) -le 0 ]]; then
    record_alarm "$user_name password will expire in $warning_date days."
  fi
}

main()
{
   prepare
   check_base_of_vm
   check_process
   check_if_passwd_expire
   return $(cat $status_result)
}

main