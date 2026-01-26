## Module 1 Homework: Docker & SQL
Q1: What's the version of pip in the image?

#### Docker command
```bash
docker run --rm -it --rm python:3.13 bash
```
##### Pip version
pip 25.3 from /usr/local/lib/python3.13/site-packages/pip (python 3.13)

Q2: Given the following docker-compose.yaml, what is the hostname and port that pgadmin should use to connect to the postgres database?

db:5432

Q3: How many trips had a trip_distance of less than or equal to 1 mile?

8,007
```sql
SELECT
	COUNT(*)
FROM
	YELLOW_TAXI_DATA
WHERE
	LPEP_PICKUP_DATETIME BETWEEN '2025-11-01' AND '2025-12-01'
	AND TRIP_DISTANCE <= 1
```

Q4: Which was the pick up day with the longest trip distance?

2025-11-20
```sql
SELECT
	LPEP_PICKUP_DATETIME::DATE,
	SUM(TRIP_DISTANCE)
FROM
	YELLOW_TAXI_DATA
WHERE
	LPEP_PICKUP_DATETIME BETWEEN '2025-11-01' AND '2025-12-01'
	AND TRIP_DISTANCE < 100
GROUP BY
	1
ORDER BY
	2 DESC
```

Q5: Which was the pickup zone with the largest total_amount (sum of all trips) on November 18th, 2025?

East Harlem North
```sql
SELECT
	TZ."Zone",
	SUM(TOTAL_AMOUNT)
FROM
	YELLOW_TAXI_DATA YT
	JOIN TAXI_ZONES TZ ON YT."PULocationID" = TZ."LocationID"
WHERE
	LPEP_PICKUP_DATETIME::DATE = '2025-11-18'
GROUP BY
	1
ORDER BY
	2 DESC
```

Q6: Which was the drop off zone that had the largest tip?

Yorkville West
```sql
SELECT
	PUZ."Zone" AS PUZ,
	DOZ."Zone" AS DOZ,
	MAX(TIP_AMOUNT)
FROM
	YELLOW_TAXI_DATA YT
	JOIN TAXI_ZONES PUZ ON YT."PULocationID" = PUZ."LocationID"
	JOIN TAXI_ZONES DOZ ON YT."DOLocationID" = DOZ."LocationID"
WHERE
	PUZ."Zone" = 'East Harlem North'
GROUP BY
	1,
	2
ORDER BY
	3 DESC
```

Q7: Which of the following sequences, respectively, describes the workflow for:

terraform init, terraform apply -auto-approve, terraform destroy