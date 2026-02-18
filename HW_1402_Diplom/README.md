
#  Дипломная работа по профессии «Системный администратор»

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

```
Файлы конфигурации:
providers.tf - Подключение к провайдеру
main.tf - создание виртуальных машин, target group, backend group, http router, ALB
network.tf - сети и подсети
security_group.tf - правила межсетевого экранирования
.gitignore - добавлен cloud-init.yml, где описаны параметры авторизации на VM
```
Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.
![Результат работы terraform. Список созданных серверов и адреса](images/image-tf.png)

```
hosts.tpl  - шаблон для inventory
hosts.tf   - генерация inventory 
outputs.tf - вывод информации после создания
ansible/ansible.cfg - настройки ansible
ansible/hosts.cfg - генерируется terraform, содержит реальные ip и fqdn
```
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
├── zabbix-agents.yml           - Установка и настройка агентов Zabbix
├── requirements.yml            - Коллекции Ansible Zabbix
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

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

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