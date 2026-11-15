with attacks as (
    select
        season, war_tag, attacker_th, defender_th, matchup, stars, destruction_pct
    from {{ ref('attacks') }}
    where attacker_th is not null
      and defender_th is not null
),

wars as (
    select season, war_tag, group_id
    from {{ ref('cwl_wars') }}
),

cwl_groups as (
    select season, group_id, division_id
    from {{ ref('cwl_groups') }}
),

matchup_totals as (
    select
        a.season,
        g.division_id,
        a.attacker_th,
        a.defender_th,
        a.matchup,
        count(*) as attacks,
        count(a.stars) as scored_attacks,
        sum(a.stars) as attack_stars,
        count(case when a.stars = 3 then 1 end) as triples,
        avg(a.destruction_pct) as avg_destruction_pct
    from attacks a
    inner join wars w
        on a.season = w.season
        and a.war_tag = w.war_tag
    inner join cwl_groups g
        on w.season = g.season
        and w.group_id = g.group_id
    group by a.season, g.division_id, a.attacker_th, a.defender_th, a.matchup
),

metrics as (
    select
        season, 
        division_id, 
        attacker_th, 
        defender_th, 
        matchup,
        attacks, 
        scored_attacks, 
        attack_stars, 
        triples, 
        avg_destruction_pct,
        1.0 * attack_stars / nullif(scored_attacks, 0) as stars_per_attack,
        100.0 * triples / nullif(scored_attacks, 0) as triple_rate_pct
    from matchup_totals
)

select * from metrics