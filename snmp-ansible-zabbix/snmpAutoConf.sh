#!/bin/bash

usage="$(basename "$0") [-h] [-s address] [-u username] [-p password] [-x cli username] [-y cli password] [-t zabbix template]

where:
    -h  show this help text
    -s  IP Fabric API url
    -u  IP Fabric user (must have read permission)
    -p  IP Fabric user's password
    -x  CLI username
    -y  CLI password
    -t  Zabbix template number for linking hosts"

if [ -f ./params.conf ]; then
  . ./params.conf
fi

while getopts ':h:s:u:p:x:y:t:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    s) IPF_SERVER=$OPTARG
       ;;
    u) IPF_USER=$OPTARG
       ;;
    p) IPF_PASSWORD=$OPTARG
       ;;
    x) CLI_USERNAME=$OPTARG
       ;;
    y) CLI_PASSWORD=$OPTARG
       ;;
    t) ZAB_TEMPLATE=$OPTARG
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND -1))

if [[ -z $IPF_SERVER || -z $IPF_USER || -z $IPF_PASSWORD || -z $CLI_USERNAME || -z $CLI_PASSWORD || -z $ZAB_TEMPLATE ]]; then
  echo "One or more variables are undefined"
  exit 1
fi

IPF_SNAPSHOT='$last'
ANSIBLE_CONFIG='ansible_ssh_inv.yml'

# Create ansible hostfile
echo "---" > $ANSIBLE_CONFIG
echo "user:" >> $ANSIBLE_CONFIG
echo "  hosts:" >> $ANSIBLE_CONFIG

while read -r sn hostname loginIp loginType; do
  NO_SNMP=$(curl -k -s "$IPF_SERVER"/v1/tables/management/snmp/summary \
    -u "$IPF_USER":"$IPF_PASSWORD" \
    -H 'Content-Type: application/json' \
    --data-binary '{"columns":["id"],"filters":{"communitiesCount":["eq",0],"sn":["eq","'"$sn"'"]},"snapshot":"'"$IPF_SNAPSHOT"'"}' | jq '._meta.size')

  if [ "$NO_SNMP" -eq '1' ]; then
    if [[ $loginType == "ssh" ]]; then
      echo "    ${hostname}:" >> $ANSIBLE_CONFIG
      echo "      ansible_host: ${loginIp}" >> $ANSIBLE_CONFIG
    else
      echo "*** WARNING *** Device ${hostname} does not use SSH! Skipping!"
    fi
  fi

  zabbix-cli -C "create_host ${hostname} 16 .+ 0"
  zabbix-cli -C "create_host_interface ${hostname} 1 2 161 ${loginIp} ${loginIp} 1"
  zabbix-cli -C "link_template_to_host ${ZAB_TEMPLATE} ${hostname}"

done< <(curl -k -s "$IPF_SERVER"/v1/tables/inventory/devices \
  -u "$IPF_USER":"$IPF_PASSWORD" \
  -H 'Content-Type: application/json' \
  --data-binary '{"columns":["sn","hostname","loginIp","loginType"],"filters":{"or":[{"family":["eq", "ios"]},{"vendor":["eq","ios-xe"]}]},"snapshot":"'"$IPF_SNAPSHOT"'"}' \
    | jq -r '.data[] | "\(.sn) \(.hostname) \(.loginIp) \(.loginType)"')

echo "  vars:" >> $ANSIBLE_CONFIG
echo "    ansible_network_os: \"ios\"" >> $ANSIBLE_CONFIG
echo "    ansible_ssh_user: ${CLI_USERNAME}" >> $ANSIBLE_CONFIG
echo "    ansible_ssh_pass: ${CLI_PASSWORD}" >> $ANSIBLE_CONFIG

echo "Running ansible"
ansible-playbook -i $ANSIBLE_CONFIG snmp-config.yml

rm $ANSIBLE_CONFIG

echo "Done"
