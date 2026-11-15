with staged_groups as (
    select
        season,
        group_id,
        division_id,
        payload
    from {{ ref('stg_groups') }}
),

groups as (
    select
        season,
        group_id,
        division_id,
        payload:state::varchar as group_state,
        array_size(payload:clans) as clan_count
    from staged_groups
)

select * from groups