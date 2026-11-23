with clan_lists as (
    select
        season,
        null::timestamp_ntz as observed_at_utc,
        payload:clans as sides
    from {{ ref('stg_groups') }}

    union all

    select
        season,
        try_to_timestamp_ntz(payload:endTime::varchar, 'YYYYMMDD"T"HH24MISS.FF3"Z"'),
        array_construct(payload:clan, payload:opponent)
    from {{ ref('stg_cwl_wars') }}
    where war_state = 'warEnded'

    union all

    select
        season,
        convert_timezone('UTC', end_time_utc)::timestamp_ntz,
        array_construct(payload:clan, payload:opponent)
    from {{ ref('stg_normal_wars') }}
),

observations as (
    select
        c.value:tag::varchar as clan_tag,
        l.season,
        l.observed_at_utc,
        c.value:name::varchar as clan_name,
        c.value:clanLevel::integer as clan_level,
        c.value:badgeUrls.medium::varchar as badge_url
    from clan_lists l,
        lateral flatten(input => l.sides) c
    where c.value:tag::varchar is not null

    union all

    select
        clan_tag,
        season,
        null::timestamp_ntz,
        null::varchar,
        null::integer,
        null::varchar
    from {{ ref('stg_normal_war_coverage') }}
    where clan_tag is not null
),

clans as (
    select distinct
        {{ coc_id('clan', ['clan_tag']) }} as id_clan,
        clan_tag,
        first_value(clan_name) ignore nulls over (
            partition by clan_tag
            order by season desc nulls last, observed_at_utc desc nulls last, clan_name
            rows between unbounded preceding and unbounded following
        ) as clan_name,
        first_value(clan_level) ignore nulls over (
            partition by clan_tag
            order by season desc nulls last, observed_at_utc desc nulls last, clan_level desc nulls last
            rows between unbounded preceding and unbounded following
        ) as clan_level,
        first_value(badge_url) ignore nulls over (
            partition by clan_tag
            order by season desc nulls last, observed_at_utc desc nulls last, badge_url
            rows between unbounded preceding and unbounded following
        ) as badge_url
    from observations
)

select * from clans