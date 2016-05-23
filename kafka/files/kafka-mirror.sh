{%- from "kafka/map.jinja" import kafka with context %}
#!/bin/sh
#
# /etc/init.d/kafka -- startup script for the kafka distributed publish-subscribe messaging system
#
# Written by Alexandros Kosiaris <akosiaris@wikimedia.org>
#
### BEGIN INIT INFO
# Provides:          kafka
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs $network
# Should-Start:      $named
# Should-Stop:       $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start kafka
# Description:       Start the kafka distributed publish-subscribe messaging system
### END INIT INFO

set -e

PATH=/bin:/usr/bin:/sbin:/usr/sbin
DESC="Kafka Mirror Maker"
DEFAULT=/etc/default/kafka-mirror

if [ `id -u` -ne 0 ]; then
  echo "You need root privileges to run this script"
	exit 1
fi

# Make sure kafka is started with system locale
if [ -r /etc/default/locale ]; then
	. /etc/default/locale
	export LANG
fi

. /lib/lsb/init-functions

if [ -r /etc/default/rcS ]; then
	. /etc/default/rcS
fi

KAFKA_RUNNER=`which kafka-run-class.sh`
if [ -z KAFKA_RUNNER ]; then
 echo "kafka-run-class.sh needs to be in $PATH"
 exit 1
fi

# The following variables can be overwritten in $DEFAULT

# Run kafka as this user ID and group ID
KAFKA_USER=kafka
KAFKA_GROUP=kafka
KAFKA_START=yes
KAFKA_JMX_OPTS=""

{% with kfg = '%s/mirror'|format(kafka.config_dir) -%}
# read in consumer config files from /etc/kafka/mirror
KAFKA_MIRROR_CONSUMER_CONFIGS=$(ls {{ kfg }}/consumer*)
KAFKA_MIRROR_PRODUCER_CONFIG=$(ls {{ kfg }}/producer*)
{% endwith -%}

KAFKA_MIRROR_NUM_STREAMS=1
KAFKA_MIRROR_NUM_PRODUCERS=1
KAFKA_MIRROR_QUEUE_SIZE=10000
KAFKA_MIRROR_WHITELIST='.*'

JAVA_HOME="{{ pillar.get('java_home') }}"
export JAVA_HOME

# Default Java options
# Set java.awt.headless=true if JAVA_OPTS is not set so the
# Xalan XSL transformer can work without X11 display on JDK 1.4+
if [ -z "$JAVA_OPTS" ]; then
	JAVA_OPTS="-Djava.awt.headless=true"
fi

# End of variables that can be overwritten in $DEFAULT

# overwrite settings from default file
if [ -f "$DEFAULT" ]; then
	. "$DEFAULT"
fi

# Define other required variables
KAFKA_MIRROR_PID="/var/run/kafka-mirror.pid"

if [ -z $KAFKA_MIRROR_CONSUMER_CONFIGS ]; then
	echo "No consumer config files provided."
	exit 1
fi
if [ -z $KAFKA_MIRROR_PRODUCER_CONFIG ]; then
	echo "No producer config file provided."
	exit 1
fi

kafka_mirror_sh() {
	# Escape any double quotes in the value of JAVA_OPTS
	JAVA_OPTS="$(echo $JAVA_OPTS | sed 's/\"/\\\"/g')"
	JMX_PORT=${JMX_PORT:-9993}
	KAFKA_JMX_OPTS="$KAFKA_JMX_OPTS -Dcom.sun.management.jmxremote.port=$JMX_PORT"

	# Define the command to run kafka as a daemon
	# set -a tells sh to export assigned variables to spawned shells.
	KAFKA_MIRROR_ARGS=" kafka.tools.MirrorMaker \
    $JAVA_OPTS \
		$KAFKA_OPTS \
		$KAFKA_JMX_OPTS \ 
		--queue.size $KAFKA_MIRROR_QUEUE_SIZE \
		--whitelist '$KAFKA_MIRROR_WHITELIST' \
		--producer.config $KAFKA_MIRROR_PRODUCER_CONFIG"

	# Add all consumer config files to KAFKA_MIRROR_ARGS
	for CONSUMER_CONFIG in $KAFKA_MIRROR_CONSUMER_CONFIGS; do
		KAFKA_MIRROR_ARGS="$KAFKA_MIRROR_ARGS --consumer.config $CONSUMER_CONFIG"
	done
	
	# Run as a daemon
	set +e

	start-stop-daemon --start -b -u "$KAFKA_USER" -g "$KAFKA_GROUP" \
		-c "$KAFKA_USER" -m -p "$KAFKA_MIRROR_PID" \
		-x "$KAFKA_RUNNER" -- $KAFKA_MIRROR_ARGS
	status="$?"
	set +a -e
	return $status
}

case "$1" in
  start)
	if [ -z "$JAVA_HOME" ]; then
		log_failure_msg "no JDK found - please set JAVA_HOME"
		exit 1
	fi

	if [ -n "$KAFKA_MIRROR_START" -a "$KAFKA_MIRROR_START" != "yes" ]; then
		log_failure_msg "KAFKA_MIRROR_START not set to 'yes' in $DEFAULT, not starting"
		exit 0
	fi

	log_daemon_msg "Starting $DESC" "kafka-mirror"
	if start-stop-daemon --test --start --pidfile "$KAFKA_MIRROR_PID" \
		--user $KAFKA_USER --exec "$KAFKA_RUNNER" \
		>/dev/null; then

		kafka_mirror_sh start
		sleep 5
		if start-stop-daemon --test --start --pidfile "$KAFKA_MIRROR_PID" \
			--user $KAFKA_USER --exec "$KAFKA_RUNNER" \
			>/dev/null; then
			if [ -f "$KAFKA_MIRROR_PID" ]; then
				rm -f "$KAFKA_MIRROR_PID"
			fi
			log_end_msg 1
		else
			log_end_msg 0
		fi
	else
	        log_progress_msg "(already running)"
		log_end_msg 0
	fi
	;;
  stop)
	log_daemon_msg "Stopping $DESC" "kafka-mirror"

	set +e
	if [ -f "$KAFKA_MIRROR_PID" ]; then
		start-stop-daemon --stop --pidfile "$KAFKA_MIRROR_PID" \
			--user "$KAFKA_USER" \
			--retry=TERM/20/KILL/5 >/dev/null
		if [ $? -eq 1 ]; then
			log_progress_msg "$DESC is not running but pid file exists, cleaning up"
		elif [ $? -eq 3 ]; then
			PID="`cat $KAFKA_MIRROR_PID`"
			log_failure_msg "Failed to stop kafka-mirror (pid $PID)"
			exit 1
		fi
		rm -f "$KAFKA_MIRROR_PID"
	else
		log_progress_msg "(not running)"
	fi
	log_end_msg 0
	set -e
	;;
   status)
	set +e
	start-stop-daemon --test --start --pidfile "$KAFKA_MIRROR_PID" \
		--user $KAFKA_USER --exec "$KAFKA_RUNNER" \
		>/dev/null 2>&1
	if [ "$?" = "0" ]; then

		if [ -f "$KAFKA_MIRROR_PID" ]; then
		    log_success_msg "$DESC is not running, but pid file exists."
			exit 1
		else
		    log_success_msg "$DESC is not running."
			exit 3
		fi
	else
		log_success_msg "$DESC is running with pid `cat $KAFKA_MIRROR_PID`"
	fi
	set -e
        ;;
  restart|force-reload)
	if [ -f "$KAFKA_MIRROR_PID" ]; then
		$0 stop
		sleep 1
	fi
	$0 start
	;;
  try-restart)
        if start-stop-daemon --test --start --pidfile "$KAFKA_MIRROR_PID" \
		--user $KAFKA_USER --exec "$KAFKA_RUNNER" \
		>/dev/null; then
		$0 start
	fi
        ;;
  *)
	log_success_msg "Usage: $0 {start|stop|restart|try-restart|force-reload|status}"
	exit 1
	;;
esac

exit 0
