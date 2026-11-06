CREATE OR REFRESH MATERIALIZED VIEW
silver_flights_rejected AS

WITH ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY flight_id
            ORDER BY flight_id
        ) AS rn
    FROM bronze_airline_flights
),

deduplicated AS (
    SELECT *
    FROM ranked
    WHERE rn = 1
)

SELECT *,
    CASE
        WHEN passengers > seat_capacity
            THEN 'Passengers more than seats'

        WHEN passengers < 0
            THEN 'Negative passengers'

        WHEN avg_fare < 0
            THEN 'Average fare is negative'
    END AS reject_reason

FROM deduplicated

WHERE passengers > seat_capacity
   OR passengers < 0
   OR avg_fare < 0;

CREATE OR REFRESH MATERIALIZED VIEW
silver_flights_clean AS

WITH ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY flight_id
            ORDER BY flight_id
        ) AS rn
    FROM bronze_airline_flights
),

deduplicated AS (
    SELECT *
    FROM ranked
    WHERE rn = 1
)

SELECT
    * EXCEPT (rn, airline),

    CASE
        WHEN airline IS NULL OR TRIM(airline) = ''
        THEN 'Unknown'
        ELSE INITCAP(TRIM(airline))
    END AS airline,

    CASE
        WHEN delay_minutes <= 15 THEN 'On Time'
        ELSE 'Delayed'
    END AS delay_category

FROM deduplicated

WHERE passengers <= seat_capacity
  AND passengers >= 0
  AND avg_fare >= 0;

