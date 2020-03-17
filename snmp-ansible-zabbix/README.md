SNMP Auto Configurator for Zabbix Server
===========

This bash script allows you to import IOS and IOS-XE devices that were automatically discovered using [IP Fabric](https://ipfabric.io) into a Zabbix server and enable SNMP protocol in appliances using Ansible.

## Requirements

### jq

Please follow [the official instructions](https://stedolan.github.io/jq/download/).

### Ansible

Ansible version > 2.6.0 is required. To install the latest version available on Linux Debian, please execute:
```
echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" | tee -a /etc/apt/sources.list
```
Aferwards execute the following commands:
```
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
sudo apt update
sudo apt install ansible
```
Or follow [the official documentation](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-debian).

### zabbix-cli

`zabbix-cli` version >= 2.1.0 is supported. which can be installed from RPM package or directly from source-code with git repository.

Please obtain [the newest RPM package available](https://github.com/unioslo/zabbix-cli/releases) and install it by running `yum install <rpm file>`.
To install `zabbix-cli` from the source code, please follow [the official instructions](https://github.com/unioslo/zabbix-cli/blob/master/docs/manual.rst#installing-from-source).

## Configuration

### Ansible

If you do not use ssh-rsa key for every appliance on your server, it will be necessary to enable one setting in ansible `.CONFIG` file. Edit `/etc/ansible/ansible.cfg` and make sure that parameter `host_key_checking` is set to `False`:
```
[defaults]
host_key_checking = False
```

### zabbix-cli

Make sure that `zabbix-cli` is configured.
It can be configured using:
```
zabbix-cli-init -z https://<your-zabbix-server>/zabbix/
```
It will create .config file under `~/.zabbix-cli/zabbic.cli.config`. Below is part of configuration that can be changed later on:
```
[zabbix_api]
zabbix_api_url = https://<your-zabbic-server>/zabbix/
cert_verify = OFF

[zabbix_config]
default_hostgroup = All-hosts
```
Where `zabbix_api_url` is zabbix server address. `cert_verify = ON` depends if we are using certificate for Zabbix server. `default_hostgroup = All-hosts` this setting is default group which our appliances will be imported to. 

We need to authenticate our script to zabbix server. For session purposes we can save username and password using:
```
export ZABBIX_USERNAME=zbxuser
read -srp "Zabbix Password: " ZABBIX_PASSWORD; export ZABBIX_PASSWORD;
zabbix-cli
```

## Usage

For help please run:
```
./snmpAutoconfig.sh -h
```
