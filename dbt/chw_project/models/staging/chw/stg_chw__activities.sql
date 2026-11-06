{{ config(
    materialized = 'view'
) }}

with source_data as (

    select * from {{ source('chw_source', 'fct_chv_activity') }}

),

standardized as (

    select
        -- Primary Key
        activity_id::varchar as activity_id,

        -- Foreign Keys & Entities
        chv_id::varchar as chv_id,
        household_id::varchar as household_id,
        patient_id::varchar as patient_id,
        location_code::varchar as location_code,

        -- Event Dates & Timestamps
        activity_date::date as activity_date,
        activity_timestamp::timestamp as activity_timestamp,
        
        -- Calculated Reporting Month (26th-day cutoff)
        {{ month_assignment('activity_date') }} as report_month,

        -- Classifications & Attributes
        lower(trim(activity_type)) as activity_type,
        coalesce(is_deleted, false) as is_deleted,

        -- Metadata Timestamps
        created_at::timestamp as created_at,
        updated_at::timestamp as updated_at

    from source_data

)

select * from standardized