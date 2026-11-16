with registered as (
    select id_clan, clan_tag, clan_name, season, clan_level
    from ({{ coc_group_clans(ref('stg_groups')) }}) as extracted_group_clans
),

normal_wars as (
    select id_clan, id_opponent_clan, clan_tag, opponent_tag, season, payload
    from {{ ref('stg_normal_wars') }}
),

coverage as (
    select id_clan, clan_tag, season
    from {{ ref('stg_normal_war_coverage') }}
),

name_observations as (
    select id_clan, clan_tag, clan_name, season, 1 as source_priority
    from registered

    union all

    select id_clan, clan_tag, payload:clan.name::varchar, season, 2
    from normal_wars

    union all

    select id_opponent_clan, opponent_tag, payload:opponent.name::varchar, season, 2
    from normal_wars

    union all

    select id_clan, clan_tag, null::varchar, season, 3
    from coverage
),

latest_names as (
    select
        id_clan,
        clan_tag,
        clan_name,
        case when clan_name is not null then season end as name_observed_season
    from name_observations
    qualify row_number() over (
        partition by id_clan
        order by (clan_name is null), season desc nulls last, source_priority, clan_name
    ) = 1
),

latest_levels as (
    select id_clan, clan_level, season as level_observed_season
    from registered
    where clan_level is not null
    qualify row_number() over (
        partition by id_clan
        order by season desc nulls last, clan_level desc
    ) = 1
),

clans as (
    select
        n.id_clan,
        n.clan_tag,
        n.clan_name,
        n.name_observed_season,
        l.clan_level,
        l.level_observed_season
    from latest_names n
    left join latest_levels l on n.id_clan = l.id_clan
)

select * from clans