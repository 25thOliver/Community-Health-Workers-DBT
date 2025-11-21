{{ config(
    materialized = 'incremental',
    incremental_strategy = 'delete+insert',
    unique_key = ['chv_id', 'report_month']
)}}

-- Monthly rollup per CHW (one rwo per chv_id + report_month)
with raw as (
    
    -- Source filtering: exclude invalid or deleted records
    select
        activity_id,
        chv_id,
        activity_date,
        activity_type,
        household_id,
        patient_id,
        is_deleted
    from {{ source('marts', 'fct_chv_activity') }}

    where activity_date is not null
        and chv_id is not null
        and (is_deleted is false or is_deleted is null) -- null treated as not deleted

),

assigned as (
    -- assign each activity to a report_month according to the 26th-day
    select
        activity_id,
        chv_id,
        activity_date,
        activity_type,
        household_id,
        patient_id,
        {{ month_assignment('activity_date') }} as report_month
    from raw
),

aggregated as (

    -- aggregate to the target grain: one row per chv_id + report_month
    select
        chv_id::varchar as chv_id,
        report_month::date as report_month,
        count(*)::int as total_activities,
        count(distinct household_id)::int as unique_households_visited,
        count(distinct patient_id)::int as unique_patients_served,
        sum(case when activity_type = 'pregnancy_visit' then 1 else 0 end)::int as pregnancy_visits,
        sum(case when activity_type = 'child_assessment' then 1 else 0 end)::int as child_assessments,
        sum(case when activity_type = 'family_planning' then 1 else 0 end):: family_planning_visits
    from assigned
    group by chv_id, report_month
    
)

select * from aggregated

