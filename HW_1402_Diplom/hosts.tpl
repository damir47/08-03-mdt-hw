[all:vars]
ansible_user=user
ansible_ssh_private_key_file=~/.ssh/ansible
ansible_ssh_common_args="-o ProxyCommand=\"ssh -q user@${bast_ip} -i ~/.ssh/ansible -W %h:%p\""

[bastion]
bastion ansible_host=${bast_ip}

[nginx]
web01 ansible_host=${web01_hostname}.ru-central1.internal
web02 ansible_host=${web02_hostname}.ru-central1.internal

[zabbix]
zabbix ansible_host=${zabbix_hostname}.ru-central1.internal

[kibana]
kibana ansible_host=${kibana_hostname}.ru-central1.internal

[elastic]
elastic ansible_host=${elastic_hostname}.ru-central1.internal

[web:children]
nginx

[elk:children]
elastic
kibana

[all:children]
bastion
nginx
zabbix
elk