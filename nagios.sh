#!/bin/bash
#
# Purpose: nagios deployment script for SDCE project
# Author: iklema
# Location:
# Versions: v.0.2
# 20180921 initial version
# 
# TODOs:
#download package
#start and check nagios


### ====  Creating filesystem for nagiosmon user ====
VG="localvg"
vgs ${VG} >/dev/null
if [ $? -eq 0 ]; then
  echo "==== VG localvg already exists ===="
  vgs ${VG}
  echo -e "\n"
else 
  echo "VG localvg doesn't exists, please create VG!!!!"
  exit 1
fi

lvs /dev/${VG}/lv_nagiosmon >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "==== LV lv_nagiosmon exists ===="
  lvs /dev/${VG}/lv_nagiosmon
  echo -e "\n"
else
  lvcreate -n lv_nagiosmon -L 500M -W y -Z y -y localvg
  if [ $? -eq 0 ]; then
    mkfs.ext4  /dev/localvg/lv_nagiosmon
    echo "==== LV lv_nagiosmon created ===="
    lvs /dev/${VG}/lv_nagiosmon
    echo -e "\n"
  else echo "there is not enough space for lv_nagiosmon"
    exit 1
  fi
fi  

#grep -v ^# /etc/fstab | grep lv_nagiosmon >/dev/null
grep -q "^/dev/${VG}/lv_nagiosmon.*/nagiosmon" /etc/fstab
if [ $? -eq 0 ]; then
    echo "==== fstab entry exists ===="
else 
    echo "/dev/localvg/lv_nagiosmon       /nagiosmon  ext4    defaults 1 2" >> /etc/fstab
fi

df /nagiosmon >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "==== mountpoint exists ===="
else 
  mkdir -p /nagiosmon
  mount /nagiosmon
fi

mount | grep /nagiosmon >/dev/nul
if [ $? -eq 0 ]; then
  echo -e "\n"
  echo "==== Everything is ready for nagios installation ===="
  echo -e "\n"
else
  mount /nagiosmon
  #TODO check if mount was successful
  echo "==== Filesystem /nagiosmon has been mounted ====" 
  echo "==== Everything is ready for nagios installation ===="
fi 

### ==== Create user and group ====

getent group nagiosmon >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "==== Group nagiosmon already exists! ===="
else 
  groupadd nagiosmon
  echo "==== Group nagiosmon created ===="
fi

id nagiosmon >/dev/null 2>&1 
if [ $? -eq 0 ]; then
  echo "==== User nagiosmon exists! ===="
  id nagiosmon
else 
  useradd -g nagiosmon -c "TSI nagios user" -d /nagiosmon nagiosmon 2>/dev/null
  chown nagiosmon: /nagiosmon
  echo Start123N | passwd nagiosmon --stdin >/dev/null
  echo "==== User nagiosmon has been created and password is set ===="
fi

### ==== Create crontab for user ====
echo "==== Crontab for nagiosmon ===="
#escapoval som "
crontab -l -u nagiosmon 2>/dev/null| grep -e run_nrpe.sh || true; echo "*/5 * * * * /bin/ps -ef | grep \"bin/nrpe\" | /bin/grep -v grep || ~/run_nrpe.sh start" |crontab - -u nagiosmon
 
###test
##test1
