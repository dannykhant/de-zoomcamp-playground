from kafka import KafkaConsumer
from models import ride_deserializer


server = 'localhost:9092'
topic_name = "green-trips"

consumer = KafkaConsumer(
    topic_name,
    bootstrap_servers=[server],
    auto_offset_reset='earliest',
    group_id='rides-console',
    value_deserializer=ride_deserializer
)

count = 0
for message in consumer:
    ride = message.value
    if ride.trip_distance > 5:
        count += 1
        print(count, ride)

consumer.close()
print(f"Total rides with distance > 5 miles: {count}")
