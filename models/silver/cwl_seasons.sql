with staged_groups as (
    select season
    from {{ ref('stg_groups') }}
    where season is not null
),

seasons as (
    select distinct
        season,
        to_date(season || '-01', 'YYYY-MM-DD') as month_start_date
    from staged_groups
)

select * from seasons