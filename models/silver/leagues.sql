with staged_groups as (
    select id_division, division_id, division_name, season
    from {{ ref('stg_groups') }}
    where division_id is not null
),

divisions as (
    select
        id_division,
        division_id as division_id_source,
        division_name
    from staged_groups
    qualify row_number() over (
        partition by id_division
        order by (division_name is null), season desc nulls last, division_name
    ) = 1
)

select * from divisions