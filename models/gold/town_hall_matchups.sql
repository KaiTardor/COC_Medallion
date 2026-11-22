with attacks_with_known_th as (
    select
        month_start_date,
        id_group,
        attacker_th,
        defender_th,
        matchup,
        stars,
        destruction_pct
    from {{ ref('fct_cwl_attacks') }}
    where attacker_th is not null
      and defender_th is not null
),

cwl_groups as (
    select
        id_group,
        id_division
    from {{ ref('dim_cwl_group') }}
),

matchup_totals as (
    select
        a.month_start_date,
        g.id_division,
        a.attacker_th,
        a.defender_th,
        a.matchup,
        count(*) as attacks,
        count(a.stars) as scored_attacks,
        sum(a.stars) as attack_stars,
        count(case when a.stars = 3 then 1 end) as triples,
        count(a.destruction_pct) as attacks_with_destruction,
        sum(a.destruction_pct) as destruction_sum
    from attacks_with_known_th a
    inner join cwl_groups g on a.id_group = g.id_group
    group by a.month_start_date, g.id_division, a.attacker_th, a.defender_th, a.matchup
)

select * from matchup_totals