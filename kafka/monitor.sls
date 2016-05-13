{% from "kafka/map.jinja" import kafka_monitor as km with context %}
{% set jar_name = 'KafkaOffsetMonitor-assembly-%(version)s.jar'|format(version) %}

{% with  version = km.version   %}
{% set jar = 'KafkaOffsetMonitor-assembly-%s.jar'|format(version) %}
{% set url = '%s/%s'|format(km.source_url, jar) %}
include:
  - kafka

kafka|download-jar:
  file.managed:
    - name: {{ '%s/lib/%s'|format(kafka.real_home, jar) }}
    - source: {{ url }}
    - user: root
    - group: root
    - mode: 655


{% endwith %}
