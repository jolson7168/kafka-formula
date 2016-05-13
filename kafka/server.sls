{% from "kafka/map.jinja" import kafka, config with context %}
{% set source_url = salt['pillar.get']('kafka:source_url', kafka.default_url) %}

include:
  - kafka

{% set work_dirs = [] %}
{% if config.log.dirs is not string and config.log.dirs is sequence %}
  {% do work_dirs.extend(config.log.dirs) %}
{% elif config.log.dir is string %}
  {% do work_dirs.append(config.log.dir) %}
{% endif %}

{% if work_dirs|length >= 1 %}
# create the log dirs for brokers
kafka|create-directories:
  file.directory:
    - user: {{ kafka.user }}
    - group: {{ kafka.user }}
    - mode: 755
    - order: 10
    - makedirs: True
    - names:
        {%- for i in work_dirs %}
        - {{ i }}
        {%- endfor %}
        - {{ kafka.log_dir }}
    - recurse:
        - user
        - group
    - require:
        - sls: kafka
{% endif %}

kafka|install-dist:
  file.directory:
    - names:
        - {{ kafka.prefix }}
        - {{ kafka.config_dir }}
    - user: root
    - group: root
    - mode: 775
    - order: 10
    - makedirs: True
    - recurse:
      - user
      - group
      
  cmd.run:
    - name: curl -L '{{ source_url }}' | tar xz
    - cwd: {{ kafka.prefix }}
    - unless: test -f {{ kafka.real_home }}/config/server.properties
    - require:
        - sls: kafka
        - file: kafka|install-dist
          
  alternatives.install:
    - name: kafka-home-link
    - link: {{ kafka.alt_name }}
    - path: {{ kafka.real_home }}
    - priority: 30
    - require:
      - cmd: kafka|install-dist

kafka|server-conf:
  file.managed:
    - name: {{ kafka.config_dir }}/server.properties
    - source: salt://kafka/files/server.properties
    - user: {{ kafka.user }}
    - group: {{ kafka.user }}
    - mode: 644
    - template: jinja
    - priority: 30
    - require:
      - cmd: kafka|install-dist
    - context:
        zookeeper_connection: {{ kafka.zookeeper_conn }}
          
kafka|log4j-conf:
  file.managed:
    - name: {{ kafka.config_dir }}/log4j.properties
    - source: salt://kafka/files/log4j.properties
    - user: {{ kafka.user }}
    - group: {{ kafka.user }}
    - mode: 644
    - template: jinja
    - priority: 30
    - context:
        log_dir: {{ kafka.log_dir  }}
    - require:
      - cmd: kafka|install-dist

kafka|upstart-config:
  file.managed:
    - name: /etc/init/{{ kafka.service }}.conf
    - source: salt://kafka/files/kafka.init.conf
    - mode: 644
    - template: jinja
    - context:
        home: {{ kafka.real_home }}
        confdir: {{ kafka.config_dir }}
        user: {{ kafka.user }}
        log_dir: {{ kafka.data_dir }}
        java_home: {{ salt['pillar.get']('java_home', '/usr/lib/java') }}
    - require:
      - file: kafka|server-conf

kafka|enabled-file:
  file.managed:
    - name: /etc/default/{{ kafka.service }}
    - mode: 644
    - user: root
    - group: root
    - contents: |
        ENABLE="yes"

kafka|logrotate:
  file.managed:
    - name: /etc/logrotate.d/kafka
    - source: salt://kafka/files/logrotate.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        log_dir: /var/log/upstart/{{ kafka.service }}
        user: {{ kafka.user }}
        group: root
        rotate: 7


kafka|service:
  service.running:
    - name: {{ kafka.service }}
    - enable: true
    - init_delay: 10
    - watch:
      - file: kafka|enabled-file
      - file: kafka|upstart-config
      - file: kafka|server-conf
