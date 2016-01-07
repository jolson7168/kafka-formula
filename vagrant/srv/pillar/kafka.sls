java_home: /usr/lib/jvm/java-7-openjdk-amd64

kafka:

  lookup:
    version: '0.8.2.2'
    scala_version: '2.10'
    prefix: '/usr/lib'
    
  config:
    zookeeper:
      chroot: '/kafka'
    host_name: 'salt-master'
    advertised_host_name: 'salt-master'

zookeeper:
  config:
    snap_count: 10000
    snap_retain_count: 3
    purge_interval: 2
    max_client_cnxns: 40
