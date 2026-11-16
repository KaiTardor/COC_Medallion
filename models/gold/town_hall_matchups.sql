with attacks as (
    select season, id_group, attacker_th, defender_th, matchup, stars, destruction_pct
    from {{ ref('fct_cwl_attacks') }}
    where attacker_th is not null
      and defender_th is not null
),

matchup_totals as (
    select
        a.season,
        g.division_id,
        g.id_division,
        a.attacker_th,
        a.defender_th,
        a.matchup,
        count(*) as attacks,
        count(a.stars) as scored_attacks,
        sum(a.stars) as attack_stars,
        count(case when a.stars = 3 then 1 end) as triples,
        avg(a.destruction_pct) as avg_destruction_pct
    from attacks a
    inner join {{ ref('dim_cwl_group') }} g on a.id_group = g.id_group
    group by a.season, g.division_id, g.id_division,
        a.attacker_th, a.defender_th, a.matchup
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
        100.0 * triples / nullif(scored_attacks, 0) as triple_rate_pct,
        id_division
    from matchup_totals
)

select * from metrics