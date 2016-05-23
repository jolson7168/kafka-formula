{% from "kafka/map.jinja" import kafka,  with context  %}
{% from "kafka/macros.sls" import config_format, value_format with context %}

include:
  - kafka


kafka|debuggin:
  file.managed:
    - name: /tmp/kafka-formula_debug.log
    - user: root
    - group: root
    - mode: 644
    - contents: |
        ## lookup map data
        {% for k,v in kafka.items() -%}
        {% if k != "config" -%}
        {{ k }} => {{ v }}
        {% endif -%}
        {% endfor %}
        # EOF lookup map
        
        # config map data
        {% for x,y in kafka.config.items() -%}
        {{ x }} => {{ y }}
        {% endfor -%}
        ## EOF config map

