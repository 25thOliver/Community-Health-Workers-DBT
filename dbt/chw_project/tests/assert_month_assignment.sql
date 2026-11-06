-- tests/assert_month_assignment_boundaries.sql
-- Singular test to validate the 26th-day reporting cycle boundary logic.
-- A dbt singular test passes if and only if it returns ZERO rows.

with test_cases as (

    select
        '2024-01-25'::date as input_date,
        '2024-01-01'::date as expected_month,
        'Day 25 must remain in current month' as scenario

    union all select
        '2024-01-26'::date,
        '2024-02-01'::date,
        'Day 26 must roll into next month'

    union all select
        '2024-01-31'::date,
        '2024-02-01'::date,
        'End of month (day 31) must roll into next month'

    union all select
        '2024-02-28'::date,
        '2024-03-01'::date,
        'Feb 28 in leap year is >= 26, must roll to March'

    union all select
        '2024-02-29'::date,
        '2024-03-01'::date,
        'Feb 29 (leap day) is >= 26, must roll to March'

    union all select
        '2023-02-25'::date,
        '2023-02-01'::date,
        'Feb 25 in non-leap year must remain in February'

    union all select
        '2024-12-25'::date,
        '2024-12-01'::date,
        'Dec 25 must remain in December'

    union all select
        '2024-12-26'::date,
        '2025-01-01'::date,
        'Dec 26 must roll across year boundary to Jan of next year'

),

evaluated as (

    select
        input_date,
        expected_month,
        scenario,
        {{ month_assignment('input_date') }} as actual_month
    from test_cases

)

-- Return failures: any row where actual does not match expected
select
    input_date,
    expected_month,
    actual_month,
    scenario
from evaluated
where actual_month is distinct from expected_month