#!/bin/sh

if uname -a | grep -q -i '^Linux.*Microsoft'; then
    # ubuntu via WSL Windows Subsystem for Linux
    # hack for Windows 10 / WSL per https://stackoverflow.com/questions/62812948/volume-mounts-not-working-kubernetes-and-wsl-2-and-docker

    # IMPORTANT: make inmon, inmon/prometheus_data, inmon/grafana_data, and inmon/plugins from Windows shell, NOT
    # ubuntu! Some system flag will get set and you'll get write denied. ugh. copy over the blackbox and other files.
    # TODO: make a script for this
    echo "Installing under wsl for windows"
    
    CMD=cmd.exe
    WINDOWS_USER=$($CMD /c 'echo %USERNAME%' | sed -e 's/\r//g')
    
    INMON=inmon2
    DIRNAME="c:\\Users\\$WINDOWS_USER\\$INMON"

    if [ -d /mnt/c/Users ] ; then
	ROOT="/mnt/c/Users"
    elif [ -d /c/Users ]; then
	ROOT="/c/Users"
    else
	echo "Can't determine root dir for Users; edit the script"
	exit 1
    fi

    LINUXDIR="$ROOT/$WINDOWS_USER/$INMON"
    
    echo "tryng to mkdir $DIRNAME"
    $CMD /c "mkdir $DIRNAME"
    echo "making data dirs..."
    for i in prometheus_data grafana_data plugins ; do
	$CMD /c "mkdir $DIRNAME\\$i"
    done
    echo "copying configs..."
    for i in prometheus images blackbox grafana ; do
	cp -ap $i $LINUXDIR
    done
    echo "done. Helm installing..."

#    helm install --set pwd=/run/desktop/mnt/host/c/Users/$WINDOWS_USER/inmon internet-monitoring docker-compose/
else
    echo "Installing for Linux / OSX like normal..."
    helm install --set pwd=`pwd` internet-monitoring docker-compose/
fi

