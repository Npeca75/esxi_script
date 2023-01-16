#!/bin/ash

DST="/vmfs/volumes/storage2/"
SRC="/vmfs/volumes/disk0/"
[ -d "/vmfs/volumes/raid0" ] && SRC="/vmfs/volumes/raid0/"

esxcli system syslog config set --loghost='udp://169.254.255.254:514'
esxcli system syslog reload
esxcli network firewall ruleset set --ruleset-id=syslog --enabled=true
esxcli network firewall refresh

MSG="BACKUP: src: $SRC, dst: $DST"
esxcli system syslog mark --message="${MSG}"; echo "${MSG}"

HN=$(hostname -s)
WNR=$(date +%U)
SUFIX=$(((A%2)+1))
DST="${DST}${HN}_backup${SUFIX}/"
mkdir -p $DST

vim-cmd hostsvc/firmware/sync_config
CNF=$(vim-cmd hostsvc/firmware/backup_config|grep -oE "downloads.+$")
wget "http://127.0.0.1/${CNF}" -O "${DST}cfg_${HN}.tgz"

MSG="BACKUP: Autostop"
esxcli system syslog mark --message="${MSG}"; echo "${MSG}"
vim-cmd hostsvc/autostartmanager/autostop

re='[0-9]\+'
VMS=$(vim-cmd vmsvc/getallvms|cut -d' ' -f1|xargs)
MSG="BACKUP: $VMS"
esxcli system syslog mark --message="${MSG}"; echo "${MSG}"

IFS=' '; for VM in $VMS
do
    if expr "$VM" : "$re"; then 
        statp=$(vim-cmd vmsvc/power.getstate $VM | grep -i "power")
        name=$(vim-cmd vmsvc/get.summary $VM | grep "name = \""|cut -d'"' -f2)
        MSG="BACKUP: Check vmid: $VM, name: $name, state: $statp"
        esxcli system syslog mark --message="${MSG}"; echo "${MSG}"
        if [ "$statp" != "Powered off" ]; then
            MSG="BACKUP: Try to shutdown vmid:$VM, name: $name"
            esxcli system syslog mark --message="${MSG}"; echo "${MSG}"
            vim-cmd vmsvc/power.shutdown $VM
        fi
    fi
done

SEC=180
MSG="BACKUP: Wait for poweroff $SEC sec"
esxcli system syslog mark --message="${MSG}"; echo "${MSG}"
sleep $SEC

IFS=' '; for VM in $VMS
do
    if expr "$VM" : "$re"; then 
        statp=$(vim-cmd vmsvc/power.getstate $VM | grep -i "power")
        name=$(vim-cmd vmsvc/get.summary $VM | grep "name = \""|cut -d'"' -f2)
        MSG="BACKUP: Check vmid: $VM, name: $name, state: $statp"
        esxcli system syslog mark --message="${MSG}"; echo "${MSG}"
        if [ "$statp" != "Powered off" ]; then
            MSG="BACKUP: Try to poweroff vmid:$VM, name: $name"
            esxcli system syslog mark --message="${MSG}"; echo "${MSG}"
            vim-cmd vmsvc/power.off $VM
        fi
    fi
done

LS=$(ls -1 $SRC)
MSG="BACKUP: $SRC, $DST"$'\n'"$LS"
esxcli system syslog mark --message="${MSG}"; echo "${MSG}"
cp -fr $SRC/* $DST

MSG="BACKUP: Autostart"
esxcli system syslog mark --message="${MSG}"; echo "${MSG}"
vim-cmd hostsvc/autostartmanager/autostart

MSG="BACKUP: Done"
esxcli system syslog mark --message="${MSG}"; echo "${MSG}"

esxcli system syslog config set --loghost='udp://169.254.2.254:514'
esxcli system syslog reload
esxcli network firewall ruleset set --ruleset-id=syslog --enabled=true
esxcli network firewall refresh
