#!/bin/sh
## Flexible updating of domain blacklist
## FIRST DEFINE VARIABLES

#IPCHAIN TO USE
IPCHAIN=dnsfilter

#Action to take when match is made DROP | REJECT | LOG | <CHAINNAME>
TARGET=DROP

#see if chain exists, if not initialize
if [ `iptables -L $IPCHAIN | wc -l` -lt 1 ]; then
    echo "adding chain $IPCHAIN"
    iptables -N $IPCHAIN
    iptables -I INPUT -p udp --dport 53 -j $IPCHAIN
fi

#backup Iptables


iptables-save > /tmp/iptables_rules_$(date +%Y%m%d_%H%M%S).txt

iptables -n -L $IPCHAIN > /tmp/iptables_old.txt
old_count=$(cat /tmp/iptables_old.txt | wc -l)
echo "Rules in $IPCHAIN before update: $(expr $old_count - 2)"

#FLUSH CHAIN
iptables -F $IPCHAIN

#Add default action
iptables -A $IPCHAIN -j RETURN

##Now for the rules  -- copied from domain-blacklist.txt

# get new rules from github, replace INPUT for IPCHAIN and DROP for TARGET and apply. 

curl -s https://raw.github.com/smurfmonitor/dns-iptables-rules/master/domain-blacklist.txt | while read line; 
	do RULE=$(echo "$line" | sed -e "s/INPUT/$IPCHAIN/" -e "s/-j DROP/-j $TARGET/"); 
		eval $RULE; 
	done

iptables -n -L $IPCHAIN > /tmp/iptables_new.txt
new_count=$(cat /tmp/iptables_new.txt | wc -l)
echo "Rules in $IPCHAIN after update: $(expr $new_count - 2)"

diff /tmp/iptables_old.txt /tmp/iptables_new.txt

rm /tmp/iptables_new.txt /tmp/iptables_old.txt
