#!/bin/bash/

#Linux kernel architecture
echo "\t#Architecture\t : $(uname -a)"

#Num of available processing units. 
#Other commands <lscpu | egrep 'CPU\(s\)'>
echo "\t#CPU physical\t : $(nproc)"

#Num of vCPU. 
#Count starts from 0. Each processor will be displayed per line. 
#So wc counts the num of lines instead
echo "\t#vCPU\t\t : $(cat /proc/cpuinfo | grep processor | wc -l)"

#RAM. free -m displays memory in MB. 
#print defauls to newline at end, printf doesn't. 
#Escape % with %%.
free -m | grep Mem \
| awk 'BEGIN{
	title = "Memory Usage"; printf "\t#%s\t : ", title}
	{printf $3 "/" $2 "MB "}
	{printf ("(%.2f%%)\n", $3/$2*100)}'

# Disk. df (disk free)
# -h for more human-readability
# df -h / : displays the usage on primary drive
# df -ht ext4 : type [type]
# awk var+=$2 sums the interger of all data in col 2
df -h | grep LVMGroup \
| awk '{sumAvail+=$2; sumUsed+=$3; sumPerc+=$5} \
END {printf "\t#Disk Usage\t : %.f/%.fGb (%i%%)\n", int(sumUsed+0.5), int(sumAvail+0.5), sumPerc}'
#Other way: #END {print "Disk Usage: " sumUsed "/" sumAvail "Gb (" sumPerc "%)" }'

# CPU load. $12 is the %idle
mpstat | grep all | awk '{print 100 - $12 "%"}' | xargs echo -e "\t#CPU load\t :"

# Last reboot date and time. who -b has the most simplified output
who -b | awk '{print "\t#Last boot\t : " $3 " " $4}'

# LVM active?
# lvdisplay will have output only if LV is(are) present.
# Have 7 LV but as long 1 is present, LVM is in use.
lvdisplay | grep "LV Status"  | if [ $(grep available | wc -l) -gt 0 ]; then echo "yes"; else echo "no"; fi | xargs echo -e "\t#LVM use\t :"

# TCP Connections: netstat command
# -t : display established TCP sockets only
netstat -t | grep tcp | wc -l | xargs -i echo -e "\t#Connections TCP :" {} "ESTABLISHED"

# Server #ofusers
# who shows every login session open on the machine
who | wc -l | xargs echo -e "\t#User log\t :"

# IPv4 & MAC
# hostname -I for IPadd
# ip link for MAC. ifconfig is deprecated on Linux
echo "\t#Network\t : IP $(hostname -I)($(ip link | grep ether | awk '{print $2}'))"

# Sudo commands executed
# System set to log sudo actions in /var/log/sudo/xxx
# wc -l of each log = 2 (including incorrect pswd attempts)
unwanted=$(grep -c "incorrect password attempts" /var/log/sudo/sudo_log)
all=$(cat /var/log/sudo/sudo_log | wc -l)
executed=$((all / 2- unwanted))
echo  "\t#Sudo\t\t : $executed cmd"
