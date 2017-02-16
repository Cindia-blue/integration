#!/bin/bash
MOCO_JAR="moco-runner-0.11.0-standalone.jar"
DRIVERMANAGER_URL="/openoapi/drivermgr/v1/drivers"

L2VPN_TEMPLATE_FILE="template-l2vpn-driver.json"
L2VPN_SIMU_FILE="l2vpn_sim_file.json"
L2VPN_DRIVER_SIMU_FILENAME="L2vpnDriver.json"

SERVICE_TYPE="http"
DRIVER_LISTEN_PORT="8641";
DRIVER_SHUTDOWN_PORT="18641";
LOG_FILENAME="./logs/moco.log"

mkdir -p logs

DRIVER_IP=`ifconfig  eth0| grep "inet " | awk '{print $2}'`
cat $L2VPN_TEMPLATE_FILE | sed -e 's/DRIVER_IP/$DRIVER_IP/g' > $L2VPN_SIMU_FILE

#Register L2VPN Driver to Driver Manager
curl -d @$L2VPN_SIMU_FILE -H "Content-Type: application/json;charset=UTF-8" http://$MSB_ADDR$DRIVERMANAGER_URL

#Start the simulated driver for L2VPN
java -jar $MOCO_JAR $SERVICE_TYPE -p $DRIVER_LISTEN_PORT  -s $DRIVER_SHUTDOWN_PORT -c  $L2VPN_DRIVER_SIMU_FILENAME | tee -a $LOG_FILENAME
tail $LOG_FILENAME