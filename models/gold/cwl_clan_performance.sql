with cwl_results as (
    select
        season, 
        group_id, 
        war_id, 
        clan_tag,
        result, 
        destruction_pct, 
        attacks_available
    from {{ ref('war_results') }}
    where war_type = 'cwl'
),

groups as (
    select season, group_id, division_id
    from {{ ref('cwl_groups') }}
),

attack_rows as (
    select season, war_tag, attacker_clan_tag, stars
    from {{ ref('attacks') }}
),

attacks_by_war as (
    select
        season,
        war_tag,
        attacker_clan_tag as clan_tag,
        count(*) as attacks_used,
        count(stars) as scored_attacks,
        sum(stars) as attack_stars,
        count(case when stars = 3 then 1 end) as triples
    from attack_rows
    group by season, war_tag, attacker_clan_tag
),

season_totals as (
    select
        w.season,
        w.group_id,
        g.division_id,
        w.clan_tag,
        count(*) as wars_played,
        count(w.result) as wars_with_result,
        count(case when w.result = 'win' then 1 end) as wins,
        avg(w.destruction_pct) as avg_destruction_pct,
        sum(w.attacks_available) as attacks_available,
        sum(coalesce(a.attacks_used, 0)) as attacks_used,
        sum(coalesce(a.scored_attacks, 0)) as scored_attacks,
        sum(coalesce(a.attack_stars, 0)) as attack_stars,
        sum(coalesce(a.triples, 0)) as triples
    from cwl_results w
    left join groups g
        on w.season = g.season
        and w.group_id = g.group_id
    left join attacks_by_war a
        on w.season = a.season
        and w.war_id = a.war_tag
        and w.clan_tag = a.clan_tag
    group by w.season, w.group_id, g.division_id, w.clan_tag
),

performance as (
    select
        season, 
        group_id, 
        division_id, 
        clan_tag,
        wars_played, 
        wars_with_result, 
        wins, 
        avg_destruction_pct,
        attacks_available, 
        attacks_used, 
        scored_attacks, 
        attack_stars, 
        triples,
        100.0 * wins / nullif(wars_with_result, 0) as win_rate_pct,
        100.0 * attacks_used / nullif(attacks_available, 0) as attack_usage_pct,
        1.0 * attack_stars / nullif(scored_attacks, 0) as stars_per_attack,
        100.0 * triples / nullif(scored_attacks, 0) as triple_rate_pct
    from season_totals
)

select * from performance