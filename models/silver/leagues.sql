with staged_groups as (
    select
        division_id,
        division_name
    from {{ ref('stg_groups') }}
    where division_id is not null
      and division_name is not null
),

divisions as (
    select distinct
        division_id,
        division_name
    from staged_groups
)

select * from divisions