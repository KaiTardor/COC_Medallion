with staged_groups as (
    select
        season,
        group_id,
        payload:clans as clans_payload
    from {{ ref('stg_groups') }}
),

group_clans as (
    select
        g.season,
        g.group_id,
        c.value:tag::varchar as clan_tag,
        c.value:name::varchar as clan_name,
        c.value:clanLevel::integer as clan_level,
        array_size(c.value:members) as registered_player_count,
        c.value:members as roster_payload
    from staged_groups g,
        lateral flatten(input => g.clans_payload) c
)

select * from group_clans