#/bin/bash
priority=50
load=$(cat /proc/loadavg | awk '{ print $1 }')
if [[ "$load" > "1" ]]; then
    priority=50
else
    priority=100
fi

echo "$priority" > /etc/keepalived/loadavarage.txt
echo "Load Avarage is - $load "
echo "Priority is - $priority"