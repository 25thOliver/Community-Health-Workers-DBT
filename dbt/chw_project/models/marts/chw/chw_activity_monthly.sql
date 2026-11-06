{{ config(
    materialized = 'incremental',
    incremental_strategy = 'delete+insert',
    unique_key = 'activity_monthly_id'
) }}

/*
    chw_activity_monthly
    
    Grain: One row per CHW (chv_id) and reporting month (report_month).
    Business Rule: 26th-day reporting cycle cutoff.
    Incremental Strategy: delete+insert with a 2-month bounded lookback window
    to handle late-arriving offline syncs and supervisor edits.
*/

with activities as (

    select
        activity_id,
        chv_id,
        household_id,
        patient_id,
        location_code,
        activity_date,
        activity_timestamp,
        report_month,
        activity_type,
        is_deleted,
        updated_at
    from {{ ref('stg_chw__activities') }}

    where chv_id is not null
      and activity_date is not null
      and is_deleted = false

      {% if is_incremental() %}
          -- Bounded lookback window: recompute current month + previous 2 months
          and report_month >= (
              select coalesce(
                  (max(report_month) - interval '2 month')::date,
                  '1970-01-01'::date
              )
              from {{ this }}
          )
      {% endif %}

),

monthly_aggregates as (

    select
        -- Surrogate Primary Key
        {{ dbt_utils.generate_surrogate_key(['chv_id', 'report_month']) }} as activity_monthly_id,

        -- Natural Keys / Dimensions
        chv_id,
        report_month,

        -- Aggregated Metrics
        count(*)::int as total_activities,
        count(distinct household_id)::int as unique_households_visited,
        count(distinct patient_id)::int as unique_patients_served,

        -- Activity Type Breakdowns
        sum(case when activity_type = 'pregnancy_visit' then 1 else 0 end)::int as pregnancy_visits,
        sum(case when activity_type = 'child_assessment' then 1 else 0 end)::int as child_assessments,
        sum(case when activity_type = 'family_planning' then 1 else 0 end)::int as family_planning_visits,

        -- Metadata
        current_timestamp as dbt_updated_at

    from activities
    group by 
        chv_id, 
        report_month

)

select * from monthly_aggregates
