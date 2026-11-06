# Operational Runbook: Community Health Worker (CHW) Data Platform

This runbook documents operational procedures, incident response, backfill mechanics, and disaster recovery for the `chw_project` dbt data pipeline.

---

## 1. Routine Pipeline Operations

### A. Source Freshness Checks

Raw CHW activity logs in `public.fct_chv_activity` are expected to update continuously. Check source freshness before scheduled runs:

```bash
docker exec -it dbt_runner dbt source freshness --target docker
```

- **Warning SLA:** No new records within 24 hours.
- **Error SLA:** No new records within 48 hours (indicates upstream ingestion or tablet sync pipeline outage).

### B. Standard Incremental Execution

The pipeline runs incrementally on a scheduled cadence (e.g. nightly or hourly):

```bash
docker exec -it dbt_runner dbt build --select marts.chw --target docker
```

- Automatically builds models and executes schema tests sequentially.
- Recomputes only the current reporting month and the prior 2 months via bounded lookback.

---

## 2. Handling Historical Corrections & Backfills

### Scenario A: Revisions Within the Last 2 Months

- **Action Required:** None.
- **Why:** The incremental model `chw_activity_monthly` automatically evaluates:

  ```sql
  report_month >= max(report_month) - interval '2 month'
  ```

  Any late-arriving visits or edited records within this 2-month window are absorbed, recalculated, and updated via `delete+insert` automatically on the next scheduled run.

### Scenario B: Deep Historical Revisions (> 2 Months Ago)

If historical data older than 2 months has been updated or re-ingested:

#### Option 1: Full Refresh Rebuild

To completely recompute all historical months from scratch:

```bash
docker exec -it dbt_runner dbt run --select chw_activity_monthly --full-refresh --target docker
```

> **Note:** In PostgreSQL, `--full-refresh` drops the existing table and recreates it. Avoid running this during peak BI reporting hours.

#### Option 2: Parameterized Historical Backfill (Zero Downtime)

If you need to recompute a specific historical window without dropping the table, execute an ad-hoc dbt run overriding the incremental logic:

```bash
docker exec -it dbt_runner dbt run --select chw_activity_monthly --vars '{"backfill_start_date": "2023-01-01"}' --target docker
```

---

## 3. Incremental vs. Full-Refresh Reconciliation

To verify that the incremental model has zero metric drift compared to a full historical rebuild:

### Step 1: Build a Shadow Reconciliation Table

```bash
docker exec -it dbt_runner dbt run --select chw_activity_monthly --full-refresh --target docker
```

### Step 2: Run Reconciliation Query in PostgreSQL

```sql
SELECT
    COUNT(*) AS total_rows,
    SUM(total_activities) AS grand_total_activities,
    SUM(unique_households_visited) AS total_households_sum,
    SUM(pregnancy_visits) AS total_pregnancy_visits
FROM public.chw_activity_monthly;
```

Compare these metrics against the raw source counts within the active window to ensure 100% row-for-row reconciliation.

---

## 4. Disaster Recovery & Troubleshooting

### Error: `dbt test` fails with duplicate key violations

- **Cause:** Two records generated the same `(chv_id, report_month)` combination.
- **Triage:** Query `stg_chw__activities` to check if `chv_id` or date types were modified unexpectedly:

  ```sql
  SELECT chv_id, report_month, COUNT(*)
  FROM public.stg_chw__activities
  GROUP BY chv_id, report_month
  HAVING COUNT(*) > 1;
  ```

### Error: Elevated Rejection Count in `stg_chw__rejected_activities`

- **Cause:** Spike in records missing `chv_id`, missing `activity_date`, or flagged `is_deleted = true`.
- **Triage:** Query the audit view to identify the root cause:

  ```sql
  SELECT rejection_reason, COUNT(*) AS rejected_count
  FROM public.stg_chw__rejected_activities
  GROUP BY rejection_reason
  ORDER BY rejected_count DESC;
  ```

- **Escalation:** If `missing_chv_id` spikes, notify the mobile engineering team responsible for the tablet data collection app.