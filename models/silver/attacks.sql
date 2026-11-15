with participants as (
    select
        season,
        war_tag,
        clan_tag,
        player_tag,
        town_hall_level,
        attacks_used,
        attacks_payload
    from {{ ref('cwl_war_participants') }}
),

attackers as (
    select
        season, 
        war_tag, 
        clan_tag, 
        player_tag,
        town_hall_level, 
        attacks_payload
    from participants
    where attacks_used > 0
),

attack_rows as (
    select
        p.season,
        p.war_tag,
        a.value:"order"::integer as attack_order,
        p.clan_tag as attacker_clan_tag,
        p.player_tag as attacker_tag,
        p.town_hall_level as attacker_th,
        a.value:defenderTag::varchar as defender_tag,
        a.value:stars::integer as stars,
        a.value:destructionPercentage::float as destruction_pct
    from attackers p,
        lateral flatten(input => p.attacks_payload) a
),

classified as (
    select
        a.season,
        a.war_tag,
        a.attack_order,
        a.attacker_clan_tag,
        a.attacker_tag,
        a.attacker_th,
        d.clan_tag as defender_clan_tag,
        a.defender_tag,
        d.town_hall_level as defender_th,
        a.stars,
        a.destruction_pct,
        case
            when a.attacker_th is null or d.town_hall_level is null then null
            when a.attacker_th > d.town_hall_level then 'down-hit'
            when a.attacker_th < d.town_hall_level then 'up-hit'
            else 'same-TH'
        end as matchup
    from attack_rows a
    left join participants d
        on a.season = d.season
        and a.war_tag = d.war_tag
        and a.defender_tag = d.player_tag
)

select * from classified