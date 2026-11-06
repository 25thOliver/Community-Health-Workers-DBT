{{ config(
    materialized = 'view'
) }}

/*
    stg_chw__rejected_activities

    Audit view capturing records excluded from downstream reporting marts.
    Provides observability into field data quality issues, missing keys,
    and soft deletions.
*/

with source_data as (

    select * from {{ source('chw_source', 'fct_chv_activity') }}

),

flagged as (

    select
        activity_id::varchar as activity_id,
        chv_id::varchar as chv_id,
        activity_date::date as activity_date,
        activity_type,
        coalesce(is_deleted, false) as is_deleted,
        created_at::timestamp as created_at,
        updated_at::timestamp as updated_at,

        -- Classify rejection reason
        case
            when chv_id is null then 'missing_chv_id'
            when activity_date is null then 'missing_activity_date'
            when is_deleted = true then 'soft_deleted'
            else 'unknown'
        end as rejection_reason

    from source_data
    where
        chv_id is null
        or activity_date is null
        or is_deleted = true

)

select * from flagged