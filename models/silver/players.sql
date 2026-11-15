with roster as (
    select season, player_tag, player_name
    from {{ ref('cwl_roster') }}
    where player_tag is not null
),

lineups as (
    select season, player_tag, player_name
    from {{ ref('cwl_war_participants') }}
    where player_tag is not null
),

observations as (
    select season, player_tag, player_name, 1 as source_priority
    from lineups

    union all

    select season, player_tag, player_name, 2
    from roster
),

players as (
    select
        player_tag,
        player_name,
        case when player_name is not null then season end as name_observed_season
    from observations
    qualify row_number() over (
        partition by player_tag
        order by (player_name is null), season desc, source_priority, player_name
    ) = 1
)

select *
from players
