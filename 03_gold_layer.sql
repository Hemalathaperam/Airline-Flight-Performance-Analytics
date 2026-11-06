CREATE OR REFRESH MATERIALIZED VIEW
gold_monthly_flights AS

SELECT
    DATE_TRUNC('MONTH', flight_date) AS flight_month,
    COUNT(*) AS flights,
    SUM(passengers) AS passengers,
    SUM(seat_capacity) AS seats,

    ROUND(
        SUM(passengers) * 100.0 /
        NULLIF(SUM(seat_capacity), 0), 1
    ) AS load_factor_pct,

    SUM(ticket_revenue) AS ticket_revenue,
    SUM(fuel_cost) AS fuel_cost,

    SUM(
        CASE WHEN delay_category <> 'On Time'
        THEN 1 ELSE 0 END
    ) AS delayed_flights

FROM silver_flights_clean
GROUP BY DATE_TRUNC('MONTH', flight_date);

CREATE OR REFRESH MATERIALIZED VIEW
gold_airline_summary AS

SELECT
    airline,
    COUNT(*) AS flights,
    SUM(passengers) AS passengers,
    SUM(ticket_revenue) AS ticket_revenue,

    ROUND(
        SUM(passengers) * 100.0 /
        NULLIF(SUM(seat_capacity), 0), 1
    ) AS load_factor_pct,

    ROUND(
        SUM(CASE WHEN delay_category = 'On Time'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS on_time_pct,

    ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes

FROM silver_flights_clean
GROUP BY airline;

CREATE OR REFRESH MATERIALIZED VIEW
gold_route_summary AS

SELECT
    origin_city,
    destination_city,
    COUNT(*) AS flights,
    SUM(passengers) AS passengers,
    SUM(ticket_revenue) AS ticket_revenue,

    ROUND(
        SUM(passengers) * 100.0 /
        NULLIF(SUM(seat_capacity), 0), 1
    ) AS load_factor_pct

FROM silver_flights_clean
GROUP BY origin_city, destination_city;

CREATE OR REFRESH MATERIALIZED VIEW
gold_delay_summary AS

SELECT
    delay_category,
    delay_reason,
    COUNT(*) AS flights,
    ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes

FROM silver_flights_clean
GROUP BY delay_category, delay_reason;

CREATE OR REFRESH MATERIALIZED VIEW
gold_data_quality AS

WITH bronze_stats AS (
    SELECT
        COUNT(*) AS bronze_rows,
        COUNT(*) - COUNT(DISTINCT flight_id)
            AS duplicate_rows,

        SUM(CASE WHEN passengers > seat_capacity
            THEN 1 ELSE 0 END) AS overbooked_rows,

        SUM(CASE WHEN passengers < 0
            THEN 1 ELSE 0 END) AS negative_passenger_rows,

        SUM(CASE WHEN avg_fare < 0
            THEN 1 ELSE 0 END) AS negative_fare_rows,

        SUM(CASE WHEN airline IS NULL OR TRIM(airline) = ''
            THEN 1 ELSE 0 END) AS missing_airline_rows,

        SUM(CASE WHEN delay_minutes IS NULL
            THEN 1 ELSE 0 END) AS missing_delay_rows,

        SUM(CASE WHEN ticket_revenue IS NULL
            THEN 1 ELSE 0 END) AS missing_revenue_rows,

        SUM(CASE WHEN delay_reason IS NULL
                  OR TRIM(delay_reason) = ''
            THEN 1 ELSE 0 END) AS missing_reason_rows

    FROM bronze_airline_flights
),

silver_stats AS (
    SELECT COUNT(*) AS clean_rows
    FROM silver_flights_clean
),

rejected_stats AS (
    SELECT COUNT(*) AS rejected_rows
    FROM silver_flights_rejected
)

SELECT *
FROM bronze_stats
CROSS JOIN silver_stats
CROSS JOIN rejected_stats;