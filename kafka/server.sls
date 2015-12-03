{%- from 'kafka/settings.sls' import kafka, config with context %}

include:
  - kafka

kafka-directories:
  file.directory:
    - user: kafka
    - group: kafka
    - mode: 755
    - makedirs: True
    - names:
{% for log_dir in config.log_dirs %}
      - {{ log_dir }}
{% endfor %}


install-kafka-dist:
  cmd.run:
    - name: curl -L '{{ kafka.source_url }}' | tar xz
    - cwd: /usr/lib
    - unless: test -d {{ kafka.real_home }}/config
  alternatives.install:
    - name: kafka-home-link
    - link: {{ kafka.prefix }}
    - path: {{ kafka.real_home }}
    - priority: 30
    - require:
      - cmd: install-kafka-dist

kafka-server-conf:
  file.managed:
    - name: {{ kafka.real_home }}/config/server.properties
    - source: salt://kafka/config/server.properties
    - user: kafka
    - group: kafka
    - mode: 644
    - template: jinja
    - priority: 30
    - require:
      - cmd: install-kafka-dist

/etc/init/kafka.conf:
  file.managed:
    - source: salt://kafka/config/kafka.init.conf
    - mode: 644
    - template: jinja
    - context:
      workdir: {{ kafka.prefix }}
    - require:
      - file: kafka-server-conf

kafka-service:
  service.running:
    - name: kafka
    - enable: true
    - watch:
      - file: kafka-server-conf
      - file: /etc/init/kafka.conf
