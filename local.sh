# Note: This script will not be run when UEFI secure boot is enabled.

/bin/kill $(cat /var/run/crond.pid)
/bin/echo "5 1 * * 0 /vmfs/volumes/storage2/weekly.sh" >> /var/spool/cron/crontabs/root
crond

#enable LLDP
vsish -e set /net/portsets/bond0/ports/2214592519/lldp/enable 1
vsish -e set /net/portsets/bond0/ports/2214592521/lldp/enable 1

exit 0
