with cwl_months as (
    select month_start_date
    from {{ ref('cwl_seasons') }}
),

normal_war_end_times as (
    select end_time_utc
    from {{ ref('normal_wars') }}
    where observed_a or observed_b
),

normal_months as (
    select cast(date_trunc('month', convert_timezone('UTC', end_time_utc)) as date) as month_start_date
    from normal_war_end_times
),

periods as (
    select month_start_date from cwl_months

    union

    select month_start_date from normal_months
),

months as (
    select
        month_start_date,
        to_char(month_start_date, 'YYYY-MM') as month_label,
        year(month_start_date) as year_number,
        month(month_start_date) as month_number
    from periods
)

select * from months