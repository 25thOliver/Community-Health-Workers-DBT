{% macro month_assignment(date_column) -%}
(
    case
        when {{ date_column }} is null then null
        when date_part('day', {{ date_column }})::int >= 26
            then date_trunc('month', ({{ date_column }} + interval '1 month'))::date
        else date_trunc('month', {{ date_column }})::date
    end
)
{%- endmacro %}