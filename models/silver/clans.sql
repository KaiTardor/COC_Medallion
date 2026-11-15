with registered_clans as (
    select
        season,
        clan_tag,
        clan_name
    from {{ ref('group_clans') }}
    where clan_tag is not null
),

normal_wars as (
    select
        season,
        clan_tag,
        opponent_tag,
        payload
    from {{ ref('stg_normal_wars') }}
),

observations as (
    select season, clan_tag, clan_name, 1 as source_priority
    from registered_clans

    union all

    select season, clan_tag, payload:clan.name::varchar, 2
    from normal_wars
    where clan_tag is not null

    union all

    select season, opponent_tag, payload:opponent.name::varchar, 2
    from normal_wars
    where opponent_tag is not null
),

clans as (
    select
        clan_tag,
        clan_name,
        case when clan_name is not null then season end as name_observed_season
    from observations
    qualify row_number() over (
        partition by clan_tag
        order by (clan_name is null), season desc, source_priority, clan_name
    ) = 1
)

select *
from clans
