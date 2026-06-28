import os
import pika
import json
import time

from app.orders import create_order

RABBITMQ_USER = os.getenv('RABBITMQ_USER')
RABBITMQ_PASSWORD = os.getenv('RABBITMQ_PASS')
RABBITMQ_HOST = os.getenv('RABBITMQ_HOST')
RABBITMQ_PORT = os.getenv('RABBITMQ_PORT')
RABBITMQ_QUEUE = os.getenv('RABBITMQ_QUEUE')


def consume_and_store_order(app, db):  
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASSWORD)
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(RABBITMQ_HOST, RABBITMQ_PORT, '/', credentials)
    )
    channel = connection.channel()
    channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True, arguments={"x-queue-type": "quorum"})
    
    def callback(ch, method, properties, body):
        print(f" [.] received: {body.decode()}", flush=True)
        try:
            new_order = json.loads(body.decode())
            
            
            with app.app_context():
                create_order(db.session, new_order)
                
            print(" [x] created new order", flush=True)
            ch.basic_ack(delivery_tag=method.delivery_tag)
        except Exception as error:
            print(f"Failed to process billing message: {error}", flush=True)
            channel.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
            time.sleep(5)

    channel.basic_consume(queue=RABBITMQ_QUEUE, on_message_callback=callback)
    channel.start_consuming()