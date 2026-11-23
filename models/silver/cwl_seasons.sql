with staged_groups as (
    select id_season, season
    from {{ ref('stg_groups') }}
),

seasons as (
    select distinct
        id_season,
        season,
        to_date(season || '-01', 'YYYY-MM-DD') as month_start_date
    from staged_groups
)

select * from seasons