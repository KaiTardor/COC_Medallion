with registered_clans as (
    select
        season,
        group_id,
        clan_tag,
        roster_payload
    from {{ ref('group_clans') }}
    where array_size(roster_payload) > 0
),

roster as (
    select
        c.season,
        c.group_id,
        c.clan_tag,
        m.value:tag::varchar as player_tag,
        m.value:name::varchar as player_name,
        m.value:townHallLevel::integer as town_hall_level
    from registered_clans c,
        lateral flatten(input => c.roster_payload) m
)

select * from roster