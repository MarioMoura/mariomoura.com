+++
title = "Nginx GeoIP2: logging latitude and longitude"
date = 2025-06-28T13:21:09-03:00
tags = [
    "linux",
    "nginx",
    "ansible",
    "ssh",
]
image = '/img/posts/nginx-geoip2.jpg'
comments = true
summary =  'How to configure nginx to log geolocation information, like latitude and lingitude.'
draft = false
[params]
    dotfile = false
+++

# First of all: Why?

The end goal here to have a granular view of where your server is being
requested from. That being said, this configuration allows you to parse
very precise information, like latitude and longitude, and less precise
information, like country codes.

There's also a bunch of information that you can get on the databases, we
will see how to do that and you can query what you want.

## Scope

I will show you how to configure Nginx only, not how to view the data.

## Why GeoIP2 instead of GeoIP

Simple enough, Nginx recommends it [here](https://docs.nginx.com/nginx/admin-guide/dynamic-modules/geoip/).

# Requirements

What you will need to follow this guide:
- A Server (generally a VPS, but it could be anything really) running Linux, I'm using Ubuntu.
- A MaxMind account and license key (it's **Free**). Create one [here](https://www.maxmind.com/en/geolite2/signup).
- Ansible targeting you Server. I **HIGHLY** recommend using this and not doing it manually.

## Steps

1. Get the databases
2. Configure Nginx

# Getting the databases

I recommend using this [ansible role](https://github.com/cisagov/ansible-role-geoip2).

`requirements.yml`:
```yaml
- name: geoip2
  src: https://github.com/cisagov/ansible-role-geoip2
```

Install that by using: `ansible-galaxy install --role-file requirements.yml`

On the playbook either add it as a role (like I'm doing) or use it as a task.

`playbook.yml`:
```yaml
- role: geoip2
  tags: geoip
  vars:
    geoip2_install_geoipupdate: true
    geoip2_geoipupdate_auto_update: true
    geoip2_maxmind_editions: [ "GeoLite2-ASN", "GeoLite2-City", "GeoLite2-Country" ]
    geoip2_maxmind_account_id: <account_id>
    geoip2_maxmind_license_key: <license_key>
```
**Note**: You can also configure the role using the `include_role` module and run this as a task.
Something like this:
```yaml
- name: geoip2
  include_role:
    name: geoip2
  vars:
    geoip2_install_geoipupdate: true
    geoip2_geoipupdate_auto_update: true
    geoip2_maxmind_editions: [ "GeoLite2-ASN", "GeoLite2-City", "GeoLite2-Country" ]
    geoip2_maxmind_account_id: <account_id>
    geoip2_maxmind_license_key: <license_key>
```
The variables can also be defined somewhere else, that's actually my preference.

This will download the databases to `/usr/local/share/GeoIP/*.mmdb` (using your license key). What this
will also do is enable a systemd service timer to update the databases periodically.

To check when the next run will occur run: ` systemctl status geoipupdate.timer`.

## Checking the database

Why are we checking the database? To look for the fields we can make Nginx extract.

First install the `mmdblookup` tool, on Ubuntu that means `apt install mmdb-bin`.

Second run: `mmdblookup --file /usr/local/share/GeoIP/GeoLite2-City.mmdb --ip <ip>`, I'll test it with
`8.8.8.8`.

The output is something like this, I converted it to JSON for better visualization:
```json
  {
    "continent": {
        "code": "NA",
        "geoname_id": 6255149,
        "names": {
            "de": "Nordamerika",
            "en": "North America",
            "es": "Norteamérica",
            "fr": "Amérique du Nord",
            "ja": "北アメリカ",
            "pt-BR": "América do Norte",
            "ru": "Северная Америка",
            "zh-CN": "北美洲",
          }
      },
    "country": {
        "geoname_id": 6252001,
        "iso_code": "US",
        "names": {
            "de": "USA",
            "en": "United States",
            "es": "Estados Unidos",
            "fr": "États Unis",
            "ja": "アメリカ",
            "pt-BR": "EUA",
            "ru": "США",
            "zh-CN": "美国",
          }
      },
    "location": {
        "accuracy_radius": 1000,
        "latitude": 37.751000,
        "longitude": -97.822000,
        "time_zone": "America/Chicago",
      },
    "registered_country": {
        "geoname_id": 6252001,
        "iso_code": "US",
        "names": {
            "de": "USA",
            "en": "United States",
            "es": "Estados Unidos",
            "fr": "États Unis",
            "ja": "アメリカ",
            "pt-BR": "EUA",
            "ru": "США",
            "zh-CN": "美国",
          }
      }
  }

```

We have all this information to make Nginx query for us.

# Configuring Nginx

First install the `libnginx-mod-http-geoip2` package, again I'm using Ubuntu.
I use the following Ansible task:

```yaml
- name: Install GeoIP
  apt: name=libnginx-mod-http-geoip2 state=present
```

After that we need to configure Nginx, I use a custom ansible role, there are a bunch out there I
recommend this [one](https://github.com/geerlingguy/ansible-role-nginx).

In any case, here's the Nginx config:
```nginx
load_module modules/ngx_http_geoip2_module.so;

http {
    geoip2 /usr/local/share/GeoIP/GeoLite2-Country.mmdb {
        auto_reload 5m;
        $geoip2_metadata_country_build metadata build_epoch;
        $geoip2_data_country_code default=US source=$remote_addr country iso_code;
        $geoip2_data_country_name country names en;
    }
    geoip2 /usr/local/share/GeoIP/GeoLite2-City.mmdb {
        auto_reload 60m;
        $geoip2_metadata_city_build metadata build_epoch;
        $geoip2_data_city_name default=Unknown city names en;
        $geoip2_latitude location latitude;
        $geoip2_longitude location longitude;
    }
}
```

A good documentation for the GeoIP2 module can be found in [here](https://github.com/leev/ngx_http_geoip2_module).
In summary we are setting variables for later usage. For example:
`$geoip2_data_country_code default=US source=$remote_addr country iso_code;`
is setting the variable `geoip2_data_country_code` to `country.iso_code` if nothing is found `US` is the
default. To check any field run:
`mmdblookup --file /usr/local/share/GeoIP/GeoLite2-City.mmdb --ip <ip> country iso_code`

After those variables are set, we can use them in the logging format:
```nginx
http {
    log_format json_analytics escape=json '{'
      '"msec": "$msec", '
      '"connection": "$connection", '
      '"connection_requests": "$connection_requests", '
      '"pid": "$pid", '
      '"request_id": "$request_id", '
      '"request_length": "$request_length", '
      '"remote_addr": "$remote_addr", '
      '"remote_user": "$remote_user", '
      '"remote_port": "$remote_port", '
      '"time_local": "$time_local", '
      '"time_iso8601": "$time_iso8601", '
      '"request": "$request", '
      '"request_uri": "$request_uri", '
      '"args": "$args", '
      '"status": "$status", '
      '"body_bytes_sent": "$body_bytes_sent", '
      '"bytes_sent": "$bytes_sent", '
      '"http_referer": "$http_referer", '
      '"http_user_agent": "$http_user_agent", '
      '"http_x_forwarded_for": "$http_x_forwarded_for", '
      '"http_host": "$http_host", '
      '"server_name": "$server_name", '
      '"request_time": "$request_time", '
      '"upstream": "$upstream_addr", '
      '"upstream_connect_time": "$upstream_connect_time", '
      '"upstream_header_time": "$upstream_header_time", '
      '"upstream_response_time": "$upstream_response_time", '
      '"upstream_response_length": "$upstream_response_length", '
      '"upstream_cache_status": "$upstream_cache_status", '
      '"ssl_protocol": "$ssl_protocol", '
      '"ssl_cipher": "$ssl_cipher", '
      '"scheme": "$scheme", '
      '"request_method": "$request_method", '
      '"server_protocol": "$server_protocol", '
      '"pipe": "$pipe", '
      '"gzip_ratio": "$gzip_ratio", '
      '"http_cf_ray": "$http_cf_ray",'
      '"geoip_metadata_city_build": "$geoip2_metadata_city_build",'
      '"geoip_city_name": "$geoip2_data_city_name",'
      '"latitude": "$geoip2_latitude",'
      '"longitude": "$geoip2_longitude",'
      '"geoip_country_code": "$geoip2_data_country_code"'
      '}';

    access_log /var/log/nginx/json_access.log json_analytics;
}
```

With this config we can retrieve some valuable geolocation information from incoming IPs. Notice those two lines:
```
'"latitude": "$geoip2_latitude",'
'"longitude": "$geoip2_longitude",'
```

We can later on visualize this data on another tool, like Grafana for example.
