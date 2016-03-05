{%- from 'kafka/map.jinja' import kafka, meta with context %}

kafka|setup:
  group.present:
    - name: {{ kafka.user }}

  user.present:
    - order: 1
    - name: {{ kafka.user }}
    - fullname: "Kafka Broker"
    - createhome: false
    - system: true
    - gid_from_name: True

  file.directory:
    - user: {{ kafka.user }}
    - group: {{ kafka.user }}
    - mode: 755
    - names:
        - {{ meta.real_home }}
    - recurse:
        - user
        - group
    - require:
        - user: kafka|setup
