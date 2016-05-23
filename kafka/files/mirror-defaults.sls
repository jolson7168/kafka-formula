ENABLED="yes"
LOG_DIR=/var/log/kafka/{{ service }}
CONFIG_HOME={{ config_dir }}
JAVA_HOME={{ java_home }}
KAFKA_RUNNER=`which kafka-run-class.sh`

KAFKA_CONSUMER_CONFIGS=$(ls {{ config_dir }}/mirror/consumer*)
KAFKA_PRODUCER_CONFIGS=$(ls {{ config_dir }}/mirror/consumer*)

for CONSUMER_CONFIG in $(ls {{ config_dir }}/mirror/consumer*); do
  KAFKA_MIRROR_ARGS="$KAFKA_MIRROR_ARGS --consumer.config $CONSUMER_CONFIG"
done

for PRODUCER_CONFIG in $(ls {{ config_dir }}/mirror/producer*): do
  KAFKA_MIRROR_ARGS="$KAFKA_MIRROR_ARGS --producer.config $PRODUCER_CONFIG"
done

KAFKA_MIRROR_NUM_STREAMS={{ num_streams }}
KAFKA_MIRROR_NUM_PRODUCERS={{ num_producers}}
KAFKA_MIRROR_QUEUE_SIZE={{ queue_size|default(10000)}}
KAFKA_MIRROR_WHITELIST={{ whitelist }}
