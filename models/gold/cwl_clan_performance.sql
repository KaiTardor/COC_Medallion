with cwl_results as (
    select season, id_group, id_cwl_war, id_clan, result,
        destruction_pct, attacks_available, attacks_used
    from {{ ref('fct_war_results') }}
    where war_type = 'cwl'
),

attacks_by_war as (
    select
        id_cwl_war,
        id_attacker_clan as id_clan,
        count(stars) as scored_attacks,
        sum(stars) as attack_stars,
        count(case when stars = 3 then 1 end) as triples
    from {{ ref('fct_cwl_attacks') }}
    group by id_cwl_war, id_attacker_clan
),

season_totals as (
    select
        w.season,
        w.id_group,
        w.id_clan,
        count(*) as wars_played,
        count(w.result) as wars_with_result,
        count(case when w.result = 'win' then 1 end) as wins,
        avg(w.destruction_pct) as avg_destruction_pct,
        sum(case
            when w.attacks_used is not null and w.attacks_available > 0
            then w.attacks_available
        end) as attacks_available,
        sum(case
            when w.attacks_used is not null and w.attacks_available > 0
            then w.attacks_used
        end) as attacks_used,
        sum(coalesce(a.scored_attacks, 0)) as scored_attacks,
        sum(coalesce(a.attack_stars, 0)) as attack_stars,
        sum(coalesce(a.triples, 0)) as triples
    from cwl_results w
    left join attacks_by_war a
        on w.id_cwl_war = a.id_cwl_war
        and w.id_clan = a.id_clan
    group by w.season, w.id_group, w.id_clan
),

performance as (
    select
        t.season,
        g.group_id,
        g.division_id,
        c.clan_tag,
        t.wars_played,
        t.wars_with_result,
        t.wins,
        t.avg_destruction_pct,
        t.attacks_available,
        t.attacks_used,
        t.scored_attacks,
        t.attack_stars,
        t.triples,
        100.0 * t.wins / nullif(t.wars_with_result, 0) as win_rate_pct,
        100.0 * t.attacks_used / nullif(t.attacks_available, 0) as attack_usage_pct,
        1.0 * t.attack_stars / nullif(t.scored_attacks, 0) as stars_per_attack,
        100.0 * t.triples / nullif(t.scored_attacks, 0) as triple_rate_pct,
        t.id_group,
        g.id_division,
        t.id_clan
    from season_totals t
    left join {{ ref('dim_cwl_group') }} g on t.id_group = g.id_group
    left join {{ ref('dim_clan') }} c on t.id_clan = c.id_clan
)

select * from performance