# Community Health Worker (CHW) Monthly Activity Mart (dbt)

[![dbt CI Pipeline](https://github.com/25thOliver/Community-Health-Workers-DBT/actions/workflows/ci.yml/badge.svg)](https://github.com/25thOliver/Community-Health-Workers-DBT/actions/workflows/ci.yml)

## 1. Overview

This production dbt project transforms raw Community Health Worker (CHW/CHV) visit-level event data into an analytics-ready monthly productivity summary table: `public.chw_activity_monthly`.

The resulting analytical mart powers public health dashboards, performance reviews, and resource allocation across community health programs.

---

## 2. Verified Data Architecture & DAG Flow

[ Raw Source Table ] public.fct_chv_activity (Source: chw_source) │ ├───► [ Staging View ] stg_chw__activities │ - Standardizes entity IDs, dates, and types │ - Normalizes activity_type classifications │ - Assigns reporting month via 26th-day cutoff macro │ │ │ └───► [ Analytical Mart (Incremental) ] chw_activity_monthly │ - Grain: One row per CHW per reporting month │ - Primary Key: activity_monthly_id (surrogate key) │ - Incremental: delete+insert with 2-month lookback │ └───► [ Audit / Quarantine View ] stg_chw__rejected_activities - Captures invalid records (missing CHW ID, null date, deleted) - Categorizes rejection reasons for field data quality triage


---

## 3. Core Business Rules

### A. 26th-Day Reporting Cycle
Community Health Worker reporting cycles close on the 25th of each calendar month. Any activity conducted on or after the 26th is assigned to the subsequent calendar month:
- **Jan 1 – Jan 25:** Assigned to `January (YYYY-01-01)`.
- **Jan 26 – Feb 25:** Assigned to `February (YYYY-02-01)`.
- **Dec 26 – Dec 31:** Rolls over to `January of next year ((YYYY+1)-01-01)`.

This logic is implemented defensibly in `macros/month_assignment.sql` and verified by automated singular boundary tests in `tests/assert_month_assignment.sql`.

### B. Record Filtering & Quarantine
- Valid visit records require non-null `chv_id`, non-null `activity_date`, and `is_deleted = false`.
- Any records failing these criteria are excluded from analytical metrics and surfaced in `stg_chw__rejected_activities` for operational auditing.

### C. Incremental Bounded Lookback
To handle late-arriving offline syncs from rural field workers and retrospective supervisor corrections:
- The incremental mart (`chw_activity_monthly`) evaluates the current month plus a **2-month bounded lookback window** (`report_month >= max(report_month) - interval '2 month'`).
- The model applies a `delete+insert` strategy using the unique surrogate key `activity_monthly_id = MD5(chv_id || report_month)`, ensuring idempotent re-execution without duplicate rows.

---

## 4. Analytical Mart Schema (`public.chw_activity_monthly`)

| Column Name | Data Type | Description | Tests |
| :--- | :--- | :--- | :--- |
| `activity_monthly_id` | VARCHAR | Surrogate primary key: `MD5(chv_id \|\| report_month)` | `unique`, `not_null` |
| `chv_id` | VARCHAR | Identifier of the Community Health Worker | `not_null` |
| `report_month` | DATE | Start of the assigned reporting month (`YYYY-MM-01`) | `not_null` |
| `total_activities` | INTEGER | Total valid activities performed by the CHW | `not_null` |
| `unique_households_visited` | INTEGER | Distinct households visited in the month | `not_null` |
| `unique_patients_served` | INTEGER | Distinct patients served (`NULL` patient IDs ignored) | `not_null` |
| `pregnancy_visits` | INTEGER | Count of prenatal and pregnancy visits | `not_null` |
| `child_assessments` | INTEGER | Count of child health assessments | `not_null` |
| `family_planning_visits` | INTEGER | Count of family planning consultations | `not_null` |
| `dbt_updated_at` | TIMESTAMP | Pipeline audit timestamp when the row was updated | `not_null` |

---

## 5. Quickstart & Local Development

### Prerequisites
- Docker & Docker Compose
- Git

### 1. Clone & Configure Environment
```bash
git clone https://github.com/25thOliver/Community-Health-Workers-DBT.git
cd Community-Health-Workers-DBT

# Create active local profile from template
cp dbt/chw_project/profiles.yml.example dbt/chw_project/profiles.yml
cp .env.example .env
2. Start Services
docker compose up -d
3. Verify Connection & Dependencies
docker exec -it dbt_runner dbt deps
docker exec -it dbt_runner dbt debug --target docker
4. Build & Test
# Run singular and boundary tests
docker exec -it dbt_runner dbt test --select test_type:singular --target docker

# Compile all models
docker exec -it dbt_runner dbt compile --target docker

# Execute full pipeline build
docker exec -it dbt_runner dbt build --target docker

--- 

### 5. Validation

Check `git status` and `git diff`:
```bash
git status
