{% from "kafka/map.jinja" import kafka, config_format, value_format with context  %}

include:
  - kafka


kafka|debuggin:
  file.managed:
    - name: /tmp/kafka-formula_debug.log
    - user: root
    - group: root
    - mode: 644
    - contents: |
        {% for k,v in kafka.items() %}
        {% if k == "config" %}
        {% for x,y in v.items() %}
        {{ k }} => {{ v }}
        {% endfor %}
        {% else %}
        {{ k }} => {{ v }}
        {% endif %}
        {% endfor %}
