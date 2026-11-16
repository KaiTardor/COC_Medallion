with staged_groups as (
    select id_group, id_season, id_division, group_id, payload
    from {{ ref('stg_groups') }}
),

groups as (
    select
        id_group,
        id_season,
        id_division,
        group_id as group_id_source,
        payload:state::varchar as group_state,
        array_size(payload:clans) as clan_count
    from staged_groups
)

select * from groups