#!/usr/bin/env python
# coding=utf-8
import pika
import time

# Все узлы с проброшенными портами на host
hosts = [
    {'host': 'localhost', 'port': 5672},  # rabbitmq1
    {'host': 'localhost', 'port': 5673},  # rabbitmq2  
    {'host': 'localhost', 'port': 5674}   # rabbitmq3
]

credentials = pika.PlainCredentials('damir', 'password')
connection = None

# Попытка подключения к разным узлам
for node in hosts:
    try:
        parameters = pika.ConnectionParameters(
            host=node['host'],
            port=node['port'],
            credentials=credentials,
            virtual_host='/',
            connection_attempts=3,
            retry_delay=5,
            socket_timeout=10
        )
        connection = pika.BlockingConnection(parameters)
        print(f"Connected to {node['host']}:{node['port']}")
        break
    except Exception as e:
        print(f"Failed to connect to {node['host']}:{node['port']}: {e}")
        continue

if not connection:
    print("Could not connect to any RabbitMQ node")
    exit(1)

channel = connection.channel()
# Создаем устойчивую очередь
channel.queue_declare(queue='hello', durable=True)

# Отправляем устойчивое сообщение
channel.basic_publish(
    exchange='',
    routing_key='hello',
    body='Hello Netology!',
    properties=pika.BasicProperties(
        delivery_mode=2,  # persistent mode
    )
)

print(" [x] Sent 'Hello Netology!'")
connection.close()