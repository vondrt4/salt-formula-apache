{%- from "apache/map.jinja" import server with context %}

include:
{%- if server.modules is defined %}
- apache.server.service.modules
{%- endif %}
{%- if server.mpm is defined %}
- apache.server.service.mpm
{%- endif %}

{%- if server.enabled %}

apache_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

apache_ports_config:
  file.managed:
  - name: /etc/apache2/ports.conf
  - source: salt://apache/files/ports.conf
  - template: jinja
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service

apache_security_config:
  file.managed:
  - name: {{ server.conf_dir }}/security.conf
  - source: salt://apache/files/security.conf
  - template: jinja
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service

{%- if grains.os_family == "Debian" %}
/etc/apache2/conf-enabled/security.conf:
  file.symlink:
  - target: {{ server.conf_dir }}/security.conf
  - require:
    - file: {{ server.conf_dir }}/security.conf
    - service: apache_service
{%- endif %}

{% if not grains.get('noservices', False) %}
/etc/apache2/sites-enabled/000-default.conf:
  file.absent:
    - watch_in:
      - service: apache_service
{% endif %}

apache_service:
  service.running:
  - name: {{ server.service }}
  - reload: true
  - enable: true
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}
  - require:
    - pkg: apache_packages

{%- else %}

apache_service_dead:
  service.dead:
  - name: {{ server.service }}
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

apache_remove_packages:
  pkg.purged:
  - pkgs: {{ server.pkgs }}
  - require:
    - service: apache_service_dead

{%- endif %}
