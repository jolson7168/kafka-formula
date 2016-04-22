{% from "kafka/map.jinja" import kafka with context %}
{% set version = '0.2.1' %}
{% set jar_name = 'KafkaOffsetMonitor-assembly-%(version)s.jar'|format(version) %}

{% set download_url = 'https://github.com/quantifind/KafkaOffsetMonitor/releases/download/v%(version)s/KafkaOffsetMonitor-assembly-%(version)s.jar'|format(kafka)  %}

include:
  - kafka

kafka|download-jar:
  file.managed:
    - name: {{ kafka.real_home }}/lib/KafkaOffsetMonitor-assembly-0.2.1.jar
    - source: 
