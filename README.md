# CHW Monthly Activity Aggregation(dbt Project)

## Overview

This dbt project produces a monthly summary of Community Health WOrker(CHW) activity, following the business rules provided in the project specification. The resulting model powers analytical dashboards used to evaluate CHW productivity and performance over time.

The core output of the project is an aggregated table:
`public.chw_activity_monthly`
with one row per CHV per reporting month.
