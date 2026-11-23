with clans as (
    select
        id_clan,
        clan_tag,
        clan_name,
        clan_level,
        badge_url
    from {{ ref('clans') }}
)

select * from clans