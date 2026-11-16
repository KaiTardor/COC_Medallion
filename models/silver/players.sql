with roster as (
    select id_player, season, player_tag, player_name, town_hall_level
    from ({{ coc_roster(ref('stg_groups')) }}) as extracted_roster
),

lineups as (
    select id_player, season, player_tag, player_name, town_hall_level,
        id_cwl_war, round_number
    from ({{ coc_war_participants(ref('stg_cwl_wars')) }}) as extracted_participants
),

observations as (
    select
        id_player, season, player_tag, player_name, town_hall_level,
        id_cwl_war, round_number,
        1 as source_priority
    from lineups

    union all

    select id_player, season, player_tag, player_name, town_hall_level, null, null, 2
    from roster
),

latest_names as (
    select
        id_player,
        player_tag,
        player_name,
        case when player_name is not null then season end as name_observed_season
    from observations
    qualify row_number() over (
        partition by id_player
        order by (player_name is null), season desc nulls last, source_priority, player_name
    ) = 1
),

latest_levels as (
    select id_player, town_hall_level, season as town_hall_observed_season
    from observations
    where town_hall_level is not null
    qualify row_number() over (
        partition by id_player
        order by season desc nulls last, source_priority, round_number desc nulls last,
            town_hall_level desc, id_cwl_war
    ) = 1
),

players as (
    select
        n.id_player,
        n.player_tag,
        n.player_name,
        n.name_observed_season,
        l.town_hall_level,
        l.town_hall_observed_season
    from latest_names n
    left join latest_levels l on n.id_player = l.id_player
)

select * from players