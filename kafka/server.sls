{% from  "kafka/defaults.yaml" import rawmap with context %}
{% set kafka = salt['grains.filter_by'](rawmap, grain='os', merge=salt['pillar.get']('kafka')) %}
{% set config = kafka.get('config') %}
{% set real_name = kafka.name_template % kafka %}
{% set default_url = kafka.mirror_template % {'version': kafka.version, 'name': real_name} %}
{% set real_home = '%s/%s' % (kafka.prefix, real_name) %}
{% set alt_name = '%s/kafka' % kafka.prefix %}
{% set source_url = salt['pillar.get']('kafka:source_url', default_url) %}

{% set zk_servers = salt['mine.get']('roles:zookeeper', 'network.ip_addrs', expr_form='grain').keys() %}

include:
  - kafka

# create the log dirs for brokers
kafka|log-directories:
  file.directory:
    - user: {{ kafka.user }}
    - group: {{ kafka.user }}
    - mode: 755
    - makedirs: True
    - name: {{ kafka.config.log.dir }}
    - recurse:
        - user
        - group


kafka|install-dist:
  cmd.run:
    - name: curl -L '{{ source_url }}' | tar xz
    - cwd: {{ kafka.prefix }}
    - unless: test -f {{ real_home }}/config/server.properties
    - require:
        - file: kafka|log-directories
        - sls: kafka
          
  alternatives.install:
    - name: kafka-home-link
    - link: {{ alt_name }}
    - path: {{ real_home }}
    - priority: 30
    - require:
      - cmd: kafka|install-dist

{% with port =  salt['pillar.get']("zookeeper:config:port", 2181) %}
kafka|server-conf:
  file.managed:
    - name: {{ real_home }}/config/server.properties
    - source: salt://kafka/files/server.properties
    - user: {{ kafka.user }}
    - group: {{ kafka.user }}
    - mode: 644
    - template: jinja
    - priority: 30
    - require:
      - cmd: kafka|install-dist
    - context:
        zk_list:
          {%- for i in zk_servers %}
          - {{ '%s:%d'|format(i, port)}}
          {%- endfor %}
{% endwith %}

kafka|log4j-conf:
  file.managed:
    - name: {{ real_home }}/config/log4j.properties
    - source: salt://kafka/files/log4j.properties
    - user: {{ kafka.user }}
    - group: {{ kafka.user }}
    - mode: 644
    - template: jinja
    - priority: 30
    - context:
        log_dir: {{ kafka.config.log.dir }}
    - require:
      - cmd: kafka|install-dist

kafka|upstart-config:
  file.managed:
    - name: /etc/init/{{ kafka.service }}.conf
    - source: salt://kafka/files/kafka.init.conf
    - mode: 644
    - template: jinja
    - context:
        home: {{ real_home }}
        confdir: {{ real_home }}/config
        user: {{ kafka.user }}
        log_dir: {{ kafka.config.log.dir }}
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

kafka|service:
  service.running:
    - name: {{ kafka.service }}
    - enable: true
    - init_delay: 10
    - watch:
      - file: kafka|enabled-file
      - file: kafka|upstart-config
      - file: kafka|server-conf
