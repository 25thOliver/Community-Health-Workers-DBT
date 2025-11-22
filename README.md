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

