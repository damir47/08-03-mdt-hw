
#  Дипломная работа по профессии «Системный администратор»


---------

**Скорее всего сервера перед проверкой уже выключатся (грант закончится). Если потребуется включить - свяжитесь через чат/почту и т.п. и договоримся о времени включения**

---------

# Общая структура проекта

```
user@vm-nix-ubnt09:~/terraform/diplom$ tree -L 3

├── ansible
│   ├── ansible.cfg                  - Основной конфигурационный файл Ansible
│   ├── elasticsearch.yml            - Плейбук для установки и настройки Elasticsearch
│   ├── filebeat.yml                 - Плейбук для установки и настройки Filebeat на веб-серверах
│   ├── hosts.cfg                    - Сгенерированный Terraform инвентарный файл для работы Ansible
│   ├── install-postgresql.yml       - Плейбук для установки и первичной настройки PostgreSQL на сервере Zabbix
│   ├── kibana.yml                   - Плейбук для установки и настройки Kibana
│   ├── nginx-setup.yml              - Плейбук для установки Nginx на веб-серверы и создания страницы
│   ├── site.yml                     - Главный плейбук
│   ├── templates                    - Каталог конфигурационных файлов
│   │   ├── elasticsearch.yml.j2     - Шаблон конфигурации для Elasticsearch
│   │   ├── filebeat-nginx.yml.j2    - Шаблон конфигурации модуля Filebeat для сбора логов Nginx
│   │   ├── filebeat.yml.j2          - Шаблон конфигурации Filebeat
│   │   ├── kibana.yml.j2            - Шаблон конфигурации для Kibana
│   │   ├── zabbix_agentd.conf.j2    - Шаблон конфигурации для Zabbix-агента
│   │   └── zabbix.conf.php.j2       - Шаблон конфигурационного файла для веб-интерфейса Zabbix
│   ├── vars                         - Каталог переменных Ansible
│   │   └── elastic.yml              - Переменные для настройки Elasticsearch, Kibana и Filebeat
│   ├── vault                        - Каталог для хранения секретов
│   │   ├── vault.yml                - Зашифрованный файл с паролями
│   ├── zabbix-agents.yml            - Плейбук для установки и настройки Zabbix-агентов
│   ├── zabbix-server.yml            - Плейбук для первоначальной установки Zabbix-сервера
│   └── zabbix-web-setup.yml         - Плейбук для настройки веб-интерфейса Zabbix-сервера и установки пароля администратора
├── cloud-init-nginx.yml             - Cloud-init конфигурация для веб-серверов
├── cloud-init.yml                   - Cloud-init конфигурация для всех серверов
├── hosts.tf                         - Terraform-файл, генерирующий ansible/hosts.cfg из шаблона hosts.tpl
├── hosts.tpl                        - Шаблон инвентарного файла Ansible
├── main.tf                          - Основной файл конфигурации Terraform
├── network.tf                       - Terraform-файл, описывающий сетевую инфраструктуру
├── outputs.tf                       - Terraform-файл, определяющий выходные переменные
├── providers.tf                     - Terraform-файл для настройки провайдеров
├── security_group.tf                - Terraform-файл с описанием всех групп безопасности и правил МСЭ
├── snapshot.tf                      - Terraform-файл для настройки расписания создания snapshot's
├── variables.tf                     - Terraform-файл с объявлением переменных
└── .gitignore                       - Файл со списком исключений для публикации в Git

Содержимое gitignore:
- cloud-init.yml 
- cloud-init-nginx.yml
- /ansible/vault/

```


# Скрипты Terraform: Создание серверного окружения в Яндекс облаке.

```
├── ansible
│   ├── ansible.cfg                  - Основной конфигурационный файл Ansible
│   ├── hosts.cfg                    - Сгенерированный Terraform инвентарный файл для работы Ansible
│   ├── nginx-setup.yml              - Плейбук для установки Nginx на веб-серверы и создания страницы
├── cloud-init-nginx.yml             - Cloud-init конфигурация для веб-серверов
├── cloud-init.yml                   - Cloud-init конфигурация для всех серверов
├── hosts.tf                         - Terraform-файл, генерирующий ansible/hosts.cfg из шаблона hosts.tpl
├── hosts.tpl                        - Шаблон инвентарного файла Ansible
├── main.tf                          - Основной файл конфигурации Terraform
├── network.tf                       - Terraform-файл, описывающий сетевую инфраструктуру
├── outputs.tf                       - Terraform-файл, определяющий выходные переменные
├── providers.tf                     - Terraform-файл для настройки провайдеров
├── security_group.tf                - Terraform-файл с описанием всех групп безопасности и правил МСЭ
├── variables.tf                     - Terraform-файл с объявлением переменных
└── .gitignore                       - Файл со списком исключений для публикации в Git
```

```
Содержимое cloud-init.yml:
#cloud-config
users:
  - name: user
    groups: sudo
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:                        - Тут указан SSH ключ
 
package_update: true
package_upgrade: true

packages:
  - python3
  - python3-pip
  - python3-venv
# - nginx                                       - Дополнительная строка в файле cloud-init-nginx.yml

runcmd:
  - chmod 700 /home/user/.ssh
  - chmod 600 /home/user/.ssh/authorized_keys
  - chown -R user:user /home/user/.ssh
# - systemctl enable nginx                      - Дополнительная строка в файле cloud-init-nginx.yml
# - systemctl start nginx                       - Дополнительная строка в файле cloud-init-nginx.yml
```

## Сервера были созданы
![Виртуальные машины в YC](images/imageyc-vm.png)

## Создана Target Group. WENB-сервера включены в Target Group.
![Target Group](images/image-tg.png)

## Создана Backend Group. Backends настроены на Target group, ранее созданную. Настроен healthcheck на корень (/) и порт 80, протокол HTTP
![Backend Group](images/image-back-group.png)

## Создан HTTP Router. Настроен ну группу Backend, созданную ранее.
![HTTP router](images/image-http-router.png)

## Создан Application load balancer для распределения трафика на веб-сервера, созданные ранее. Указан HTTP router, созданный ранее, задан listener тип auto, порт 80
![Application TB](images/image-alb.png)

## Установка Nginx на веб-серверы и создание страницы 
```
ansible-playbook -i hosts.cfg nginx-setup.yml --vault-password-file .vault_pass
```
![Результат работы скрипта и web-страница](images/image-nginx-config.png)

## Тестирование Работы сайта `curl -v <публичный IP балансера>:80` 
![curl -v external_ip_alb](images/image-curl.png)

## Тестирование подключения к серверам через Bastion
![ssh -J user@62.84.115.124 user@vm-yc-elk01.ru-central1.internal -i ~/.ssh/ansible](images/image-test-ssh.png)

## Результат работы Terraform
![Результат работы terraform. Список созданных серверов и адреса](images/image-tf.png)

## Содержимое файла hosts.cfg 
```
user@vm-nix-ubnt09:~/terraform/diplom$ cat ansible/hosts.cfg 
[all:vars]
ansible_user=user
ansible_ssh_private_key_file=~/.ssh/ansible
ansible_ssh_common_args="-o ProxyCommand=\"ssh -q user@93.77.176.83 -i ~/.ssh/ansible -W %h:%p\""

[bastion]
bastion ansible_host=93.77.176.83

[nginx]
web01 ansible_host=vm-yc-web01.ru-central1.internal
web02 ansible_host=vm-yc-web02.ru-central1.internal

[zabbix]
zabbix ansible_host=vm-yc-zbx01.ru-central1.internal

[kibana]
kibana ansible_host=vm-yc-kib01.ru-central1.internal

[elastic]
elastic ansible_host=vm-yc-elk01.ru-central1.internal

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

```






Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.
![Результат работы terraform. Список созданных серверов и адреса](images/image-tf.png)



Содержимое hosts.cfg
```
ser@vm-nix-ubnt09:~/terraform/diplom/ansible$ cat hosts.cfg
[all:vars]
ansible_user=user
ansible_ssh_private_key_file=~/.ssh/ansible
ansible_ssh_common_args="-o ProxyCommand=\"ssh -q user@62.84.115.124 -i ~/.ssh/ansible -W %h:%p\""

[bastion]
bastion ansible_host=62.84.115.124

[nginx]
web01 ansible_host=vm-yc-web01.ru-central1.internal
web02 ansible_host=vm-yc-web02.ru-central1.internal

[zabbix]
zabbix ansible_host=vm-yc-zbx01.ru-central1.internal

[kibana]
kibana ansible_host=vm-yc-kib01.ru-central1.internal

[elastic]
elastic ansible_host=vm-yc-elk01.ru-central1.internal

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

```

![ssh -J user@62.84.115.124 user@vm-yc-elk01.ru-central1.internal -i ~/.ssh/ansible](images/image-test-ssh.png)

Что мы видим в yandex cloud:
![Виртуальные машины в YC](images/imageyc-vm.png)


Настройка балансировщика:
1. Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.
![Target Group](images/image-tg.png)

2. Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.
![Backend Group](images/image-back-group.png)

3. Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.
![HTTP router](images/image-http-router.png)

4. Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.
![Application TB](images/image-alb.png)


Протестируйте сайт
`curl -v <публичный IP балансера>:80` 
![curl -v external_ip_alb](images/image-curl.png)

Настройка сайта через Ansible:
```
ansible-playbook -i hosts.cfg nginx-setup.yml --vault-password-file .vault_pass

```
![Результат работы скррипта и web-страница](images/image-nginx-config.png)

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

```
ansible/
├── site.yml                    - Запустить все Playbook
├── ansible.cfg                 - Конфигурация Ansible
├── hosts.cfg                   - Сгенерированный terraform inventory
├── install-postgresql.yml      - Установка и настройка PostgreSQL на сервер Zabbix
├── zabbix-server.yml           - Установка и настройка  сервера Zabbix
├── zabbix-web-setup.yml        - Настройка Web-сервера и пользователя Zabbix
├── zabbix-agents.yml           - Установка и настройка агентов Zabbix
├── requirements.yml            - Коллекции Ansible Zabbix (не стал использовать)
├── vault/
│   └── vault.yml               - Хранение секретов
└── templates/
    ├── zabbix_agentd.conf.j2   - Конфигурация агентов Zabbix
    └── zabbix.conf.php.j2      - Конфигурация сервера Zabbix
```

```
После выполнения основных скриптов terraform 
1) Создали хранилище секретов
2) Установили на сервер Zabbix PGSQL
cd ansible
ansible-playbook -i hosts.cfg install-postgresql.yml --vault-password-file .vault_pass
3) Установили Zabbix Server. Настройку пользователя вынес в отдельный скрипт.
ansible-playbook -i hosts.cfg zabbix-server.yml --vault-password-file .vault_pass
ansible-playbook -i hosts.cfg zabbix-web-setup.yml --vault-password-file .vault_pass

4) Установили Zabbix Agents
ansible-playbook -i hosts.cfg zabbix-agents.yml --vault-password-file .vault_pass
```
![Установили на сервер Zabbix PGSQL](images/image-zbx-1-pg.png)
![Установили Zabbix Server](images/image-zbx-2-srv.png)
![Установили Zabbix Agents](images/image-zbx-3-agent.png)

```
Настройка мониторинга
```
![Zabbix Console](images/image-zbx-console.png)

![Zabbix Monitoring Console](images/image-zbx-monitoring.png)

Пересоздавал сервера много раз, последний вариант страницы мониторинга

![Zabbix monitoring console](images/image-zbx-mon2.png)

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.
Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

```
ansible/
├── elasticsearch.yml      # Установка и настройка Elasticsearch на сервере elk
├── kibana.yml             # Установка и настройка Kibana на сервере kib
├── filebeat.yml           # Установка Filebeat на web01, web02
└── vars/
│   └── elastic.yml        # Переменные для Elastic стека
├── templates/
    ├── elasticsearch.yml.j2   # Конфиг Elasticsearch
    ├── kibana.yml.j2          # Конфиг Kibana
    ├── filebeat.yml.j2        # Конфиг Filebeat для nginx
    └── filebeat-nginx.yml.j2  # Конфиг модуля nginx для Filebeat
```

```
# 1. Установка Elasticsearch
ansible-playbook -i hosts.cfg elasticsearch.yml --vault-password-file .vault_pass

# 2. Установка Kibana
ansible-playbook -i hosts.cfg kibana.yml --vault-password-file .vault_pass

# 3.0 Установка Filebeat на web01 и web02
ansible-playbook -i hosts.cfg filebeat.yml --vault-password-file .vault_pass
```

![Установлен ELK](images/image-elk-elkinstall.png)
![Установлена Kibana](images/image-elk-kib.png)
![Установлен Filebeat](images/image-elk-fb.png)
![Filebeat работает](images/image-elk-fb2.png)
![WEB Интерфейс работает, данные поступают](images/image-elk-web.png)

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

Исходящий доступ в интернет для ВМ внутреннего контура через [NAT-шлюз](https://yandex.cloud/ru/docs/vpc/operations/create-nat-gateway).

![Список подсетей в YC](images/image-subnet.png)
![Список групп безопасности сети](images/image-net-sg.png)
![Bastion SG](images/image-net-bastion-sg.png)


### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.
![Terraform Apply](images/image-snap-terraform.png)
![РАсписание snapshot в YC](images/image-snap-yc.png)
### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители — работающие инженеры, которые занимаются, кроме преподавания, своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)