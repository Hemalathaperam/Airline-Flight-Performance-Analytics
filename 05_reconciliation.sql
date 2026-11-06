SELECT
    bronze_rows,
    clean_rows,
    rejected_rows,
    duplicate_rows,
    bronze_rows - clean_rows - rejected_rows - duplicate_rows AS difference,
    CASE
        WHEN bronze_rows = clean_rows + rejected_rows + duplicate_rows
        THEN 'PASSED'
        ELSE 'FAILED'
    END AS reconciliation_status
FROM aviation_catalog.flights.gold_data_quality;