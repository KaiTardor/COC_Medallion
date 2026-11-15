with wars as (
    select
        season,
        war_tag,
        payload:clan as clan,
        payload:opponent as opponent
    from {{ ref('stg_cwl_wars') }}
    where war_state = 'warEnded'
),

lineups as (
    select
        w.season,
        w.war_tag,
        s.value:tag::varchar as clan_tag,
        m.value:tag::varchar as player_tag,
        m.value:name::varchar as player_name,
        m.value:townhallLevel::integer as town_hall_level,
        m.value:mapPosition::integer as map_position,
        m.value:attacks as attacks_payload
    from wars w,
        lateral flatten(input => array_construct(w.clan, w.opponent)) s,
        lateral flatten(input => s.value:members) m
),

participants as (
    select
        season,
        war_tag,
        clan_tag,
        player_tag,
        player_name,
        town_hall_level,
        map_position,
        coalesce(array_size(attacks_payload), 0) as attacks_used,
        attacks_payload
    from lineups
)

select * from participants