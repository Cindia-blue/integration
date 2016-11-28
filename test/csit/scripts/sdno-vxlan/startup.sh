#!/bin/bash
# $1 nickname for the CATALOG instance
# $2 IP address of MSB
source ${SCRIPTS}/common_functions.sh
echo $@

#Start VXLAN
run-instance.sh openoint/sdno-service-vxlan $1 " -i -t -e MSB_ADDR=$2"
curl_path='http://'$2'/openoapi/microservices/v1/services/sdnovxlan/version/v1'
sleep_msg="Waiting_connection_of_url_for:"$1
wait_curl_driver CURL_COMMAND=$curl_path WAIT_MESSAGE='"$sleep_msg"' GREP_STRING="status"