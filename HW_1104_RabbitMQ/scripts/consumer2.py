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
            socket_timeout=10,
            heartbeat=600
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
channel.queue_declare(queue='hello', durable=True)

def callback(ch, method, properties, body):
    print(f" [x] Received {body}")
    # Имитация обработки
    time.sleep(1)
    print(" [x] Done")
    # Подтверждаем обработку
    ch.basic_ack(delivery_tag=method.delivery_tag)

# Настройка качества обслуживания
channel.basic_qos(prefetch_count=1)

channel.basic_consume(
    queue='hello',
    on_message_callback=callback,
    auto_ack=False  # Ручное подтверждение
)

print(' [*] Waiting for messages. To exit press CTRL+C')

try:
    channel.start_consuming()
except KeyboardInterrupt:
    print("Interrupted by user")
    if connection:
        connection.close()
