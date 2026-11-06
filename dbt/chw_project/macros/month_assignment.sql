{% macro month_assignment(date_column) -%}
(
    case
        when {{ date_column }} is null then null
        when extract(day from ({{ date_column }})::date)::int >= 26
            then (date_trunc('month', ({{ date_column }})::date)::date + interval '1 month')::date
        else date_trunc('month', ({{ date_column }})::date)::date
    end
)
{%- endmacro %}