{%- from 'kafka/map.jinja' import kafka, meta with context %}

kafka|user:
  group.present:
    - name: {{ kafka.user }}
  user.present:
    - name: {{ kafka.user }}
    - fullname: "Kafka Broker"
    - createhome: false
    - password: true
    - shell: /bin/bash
    - gid_from_name: True
    - groups:
      - {{ kafka.user }}

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

