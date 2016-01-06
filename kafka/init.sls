{%- from 'kafka/settings.sls' import kafka with context %}

kafka:
  group.present:
    - name: kafka
  user.present:
    - createhome: false
    - password: true
    - shell: /bin/bash
    - gid_from_name: True
    - groups:
      - kafka

# fix permissions
{{ kafka.real_home }}:
  file.directory:
    - user: kafka
    - group: kafka
    - recurse:
      - user
      - group
