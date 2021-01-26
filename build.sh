#!/bin/bash
set -e

[ -z "$APP_HOME" ] && export APP_HOME=$(pwd)
[ -z "$MONIT_VERSION" ] && export MONIT_VERSION="5.27.2"

if [ ! -f monit-$MONIT_VERSION-linux-x64.tar.gz ]; then
    echo "Monit not found, Downloading $MONIT_VERSION"
    wget https://www.mmonit.com/monit/dist/binary/$MONIT_VERSION/monit-$MONIT_VERSION-linux-x64.tar.gz
fi

rm -rf $APP_HOME/monit-$MONIT_VERSION
tar xvzf monit-$MONIT_VERSION-linux-x64.tar.gz
mkdir -p $APP_HOME/monit-$MONIT_VERSION/conf/monit.d
