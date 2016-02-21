{%- from 'kafka/map.jinja' import kafka, meta with context %}

kafka|user:
  group.present:
    - name: {{ kafka.user }}
  user.present:
    - order: 30
    - name: {{ kafka.user }}
    - fullname: "Kafka Broker"
    - createhome: false
    - system: true
    - gid_from_name: True

kafka|directories:
  file.directory:
    - user: {{ kafka.user }}
    - group: {{ kafka.user }}
    - mode: 755
    - names:
        - {{ meta.real_home }}
        - {{ kafka.config_dir }}
    - recurse:
        - user
        - group
    - order: 10
    - require:
        - user: kafka|user
