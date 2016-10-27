# Configure MSB IP address
MSB_IP=`echo $MSB_ADDR | cut -d: -f 1`
MSB_PORT=`echo $MSB_ADDR | cut -d: -f 2`
sed -i "s|MSB_SERVICE_IP.*|MSB_SERVICE_IP = '$MSB_IP'|" nfvo/lcm/lcm/pub/config/config.py
sed -i "s|MSB_SERVICE_PORT.*|MSB_SERVICE_PORT = '$MSB_PORT'|" nfvo/lcm/lcm/pub/config/config.py
sed -i "s|DB_NAME.*|DB_NAME = 'inventory'|" nfvo/lcm/lcm/pub/config/config.py
sed -i "s|DB_PASSWD.*|DB_PASSWD = 'rootpass'|" nfvo/lcm/lcm/pub/config/config.py
sed -i "s|\"ip\": \".*\"|\"ip\": \"$SERVICE_IP\"|" nfvo/lcm/lcm/pub/config/config.py
cat nfvo/lcm/lcm/pub/config/config.py

sed -i "s|127\.0\.0\.1|$SERVICE_IP|" nfvo/lcm/run.sh
sed -i "s|127\.0\.0\.1|$SERVICE_IP|" nfvo/lcm/stop.sh
