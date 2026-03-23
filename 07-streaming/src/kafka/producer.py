import pandas as pd

from time import sleep, time
from kafka import KafkaProducer

from models import ride_serializer, ride_from_row


url = "https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-10.parquet"
columns = ['lpep_pickup_datetime', 'lpep_dropoff_datetime', 
           'PULocationID', 'DOLocationID', 'passenger_count',
           'trip_distance', 'tip_amount', 'total_amount']
df = pd.read_parquet(url, columns=columns)
df['passenger_count'] = df['passenger_count'].fillna(0).astype(int)

server = 'localhost:9092'
topic_name = "green-trips"

producer = KafkaProducer(
    bootstrap_servers=[server],
    value_serializer=ride_serializer
)


t0 = time()

for _, row in df.iterrows():
    ride = ride_from_row(row)
    producer.send(topic_name, ride)
    # sleep(0.01)  # Simulate some delay between messages

producer.flush()

t1 = time()
print(f"Produced {len(df)} messages in {t1 - t0:.2f} seconds")
