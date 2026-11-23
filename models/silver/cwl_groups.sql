with groups as (
    select
        id_group,
        id_season,
        id_division,
        group_id as group_id_source
    from {{ ref('stg_groups') }}
)

select * from groups