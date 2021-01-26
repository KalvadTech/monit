#!/bin/bash
set -e

[ -z "$APP_HOME" ] && export APP_HOME=$(pwd)
[ -z "$PORT" ] && export PORT="8080"
[ -z "$MONIT_USERNAME" ] && export MONIT_USERNAME="admin"
[ -z "$MONIT_PASSWORD" ] && export MONIT_PASSWORD=$(uuidgen)
[ -z "$MONIT_VERSION" ] && export MONIT_VERSION="5.27.2"
[ -z "$HTTP_HOSTS" ] && export HTTP_HOSTS="kalvad.com/ blog.kalvad.com/"

echo "To connect to monit: username $MONIT_USERNAME, password $MONIT_PASSWORD"
cat <<EOF > $APP_HOME/monit-$MONIT_VERSION/conf/monitrc
###############################################################################
## Monit control file
###############################################################################
set daemon  5
set log syslog
set httpd port $PORT and
    allow $MONIT_USERNAME:$MONIT_PASSWORD
include $APP_HOME/monit-$MONIT_VERSION/conf/monit.d/*.conf
EOF

chmod 600 $APP_HOME/monit-$MONIT_VERSION/conf/monitrc

# HTTPS Monitoring
rm -f $APP_HOME/monit-$MONIT_VERSION/conf/monit.d/http.conf
for HTTP_HOST in $HTTP_HOSTS
do
  ADDRESS=$(echo $HTTP_HOST | cut -d '/' -f 1)
  URI=$(echo $HTTP_HOST | cut -d '/' -f 2-)
  FINAL_URI="/$URI"
  cat <<EOF >> $APP_HOME/monit-$MONIT_VERSION/conf/monit.d/http.conf
check host $ADDRESS with address $ADDRESS
      if failed
      	 port 443 protocol https request $FINAL_URI
         with timeout 3 seconds
         certificate valid > 7 days
         use ssl options {verify: enable}
         for 2 cycles
      then exec "$APP_HOME/monit-$MONIT_VERSION/scripts/slack.sh"
      else if succeeded then exec "$APP_HOME/monit-$MONIT_VERSION/scripts/slack.sh"
EOF
done

# NETWORK Monitoring
rm -f $APP_HOME/monit-$MONIT_VERSION/conf/monit.d/network.conf
INTERFACES=$(ip -o link | grep ether | awk '{ print $2 $17 }' | grep -v brd)
for INTERFACE in $INTERFACES
do
  ELEM=$(echo $INTERFACE  | cut -d ':' -f 1)
  cat <<EOF >> $APP_HOME/monit-$MONIT_VERSION/conf/monit.d/network.conf
check network "$ELEM" with interface "$ELEM"
      if failed link then exec "$APP_HOME/monit-$MONIT_VERSION/scripts/slack.sh"
      if changed link then exec "$APP_HOME/monit-$MONIT_VERSION/scripts/slack.sh"
EOF
done

# DISK Monitoring
rm -f $APP_HOME/monit-$MONIT_VERSION/conf/monit.d/disk.conf
MOUNT_POINTS=$(df -h | grep -v tmpfs | grep '%' | cut -d '%' -f 2 | awk '{ print $1}' | grep -v Mounted)
for MOUNT_POINT in $MOUNT_POINTS
do
  MOUNT_POINT_NAME=$(echo $MOUNT_POINT | sed 's/\//_slash_/g')
  echo $MOUNT_POINT_NAME
  cat <<EOF >> $APP_HOME/monit-$MONIT_VERSION/conf/monit.d/disk.conf
check filesystem $MOUNT_POINT_NAME with path $MOUNT_POINT
      if space usage > 95% then exec "$APP_HOME/monit-$MONIT_VERSION/scripts/slack.sh"
      if service time > 300 milliseconds for 5 cycles then exec "$APP_HOME/monit-$MONIT_VERSION/scripts/slack.sh"
EOF
done

#Get os
rm -f $APP_HOME/monit-$MONIT_VERSION/conf/monit.d/release.conf
rm -f $APP_HOME/monit-$MONIT_VERSION/scripts/release.sh
mkdir -p $APP_HOME/monit-$MONIT_VERSION/scripts
if [ -f "/etc/os-release" ]; then
    cat <<EOF >> $APP_HOME/monit-$MONIT_VERSION/scripts/release.sh
#!/bin/bash
cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f 2
EOF
else
    if [ -f "/etc/redhat-release" ]; then
        cat <<EOF >> $APP_HOME/monit-$MONIT_VERSION/scripts/release.sh
#!/bin/bash
cat /etc/redhat-release
EOF
    fi
fi

chmod +x $APP_HOME/monit-$MONIT_VERSION/scripts/release.sh
cat <<EOF >> $APP_HOME/monit-$MONIT_VERSION/conf/monit.d/release.conf
check program os_release with path $APP_HOME/monit-$MONIT_VERSION/scripts/release.sh with timeout 10 seconds
      if status != 0 then alert
EOF

#Slack notifications
rm -f $APP_HOME/monit-$MONIT_VERSION/scripts/slack.sh

if [ -z "$SLACK_WEBHOOK_URL" ]; then
    echo "-----No Slack"
else
    echo "-----Slack"
    cat $APP_HOME/slack.sh | sed "s#SLACK_WEBHOOK_URL#$SLACK_WEBHOOK_URL#g" > $APP_HOME/monit-$MONIT_VERSION/scripts/slack.sh
    chmod 755 $APP_HOME/monit-$MONIT_VERSION/scripts/slack.sh
fi

$APP_HOME/monit-$MONIT_VERSION/bin/monit -I -c $APP_HOME/monit-$MONIT_VERSION/conf/monitrc
