# CHW Monthly Activity Aggregation(dbt Project)

## Overview

This dbt project produces a monthly summary of Community Health WOrker(CHW) activity, following the business rules provided in the project specification. The resulting model powers analytical dashboards used to evaluate CHW productivity and performance over time.

The core output of the project is an aggregated table:
`public.chw_activity_monthly`
with one row per CHV per reporting month.


## Project Structure

```
(base) oliver@oliver-HP-EliteBook-x360-1030-G3:~/Documents/chw_dbt$ tree
.
├── dbt
│   ├── chw_project
│   │   ├── analyses
│   │   ├── dbt_packages  [error opening dir]
│   │   ├── dbt_project.yml
│   │   ├── logs  [error opening dir]
│   │   ├── macros
│   │   │   └── month_assignment.sql
│   │   ├── models
│   │   │   ├── example
│   │   │   │   ├── my_first_dbt_model.sql
│   │   │   │   ├── my_second_dbt_model.sql
│   │   │   │   └── schema.yml
│   │   │   └── starter_code
│   │   │       ├── chw_activity_monthly.sql
│   │   │       ├── schema.yml
│   │   │       └── sources.yml
│   │   ├── package-lock.yml
│   │   ├── packages.yml
│   │   ├── README.md
│   │   ├── seeds
│   │   │   └── fct_chv_activity.csv
│   │   ├── snapshots
│   │   ├── target  [error opening dir]
│   │   └── tests
│   └── logs
│       └── dbt.log
├── docker-compose.yml
└── README.md

15 directories, 15 files
(base) oliver@oliver-HP-EliteBook-x360-1030-G3:~/Documents/chw_dbt$ 
```

## Source Data

The model is built from a fact table:
`publc.fct_chv_activity`

This table stores CHW visit-level activity including:
- Activity date & timestamp
- Which CHW performed the activity
- Type of activity (pregnancy visit, child assessment, etc.)
- Household visited
- Patient served
- Is the record deleted?
- Location metadata

## Business Logic

### Reporting Month Rule

Activities are assigned to a reporting month using the rule:
     
    ACtivities on or after the 26th of a month belong to the next month.

This logic is implemented in the macro: `dbt/chw_project/macros/month_assignment.sql` 

### Record Filtering

Rows are excluded when:

- `chv_id` is NULL
- `activity_date` is NULL
- `is_deleted` = TRUE

## Output Model

`chw_activity_monthly.sql`
Produces monthly CHW activity metrics:

- `total_activities`
- `unique_households_visited`
- `unique_patients_served`
- `pregnancy_visits`
- `child_assessments`
- `family_planning_visits`

The model is incremental, using:
`unique_key = ['chv_id', 'report_month']`

## Testing

Tests include:

- `not_null` on key fields
- `dbt_utils.unique_combination_of_columns` on (`chv_id`, `report_month`)

All tests pass successfully.

## Sample Data

A rich sample dataset from the project specification was loaded into `public.fct_chv_activity` to validate:

- Month-edge behavior (26th rule)
- Duplicate household/patient logic
- Deleted/invalid record filtering
- Multiple CHWs
- Year boundary transitions (Dec → Jan)

The model output matches expected results of all scenarios.

## Running the Project

**Initialize Containers**
`docker compose up -d`

**Run dbt**
```bash
docker exec -it dbt_runner bash
cd chw_project/
dbt run
```

**Test**
`dbt test --select chw_activity_monthly`

**Inspect Output**
```bash
docker exec -it dbt_postgres bash
psql -U dbt_user -d analytics
SELECT *
FROM public.chw_activity_monthly;
```

## Recommended Enhancements

- Build a CHW dimension table (dim_chw)
- Add freshness tests for the source
- Create downstream marts for dashboards
- Add documentation site via dbt docs
- Add additional activity classifications

## Project Status

All required components have been built, validated, and tested successfully. Thus, the project now forms a solid foundation for CHW performance analytics.