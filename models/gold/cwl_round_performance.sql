with cwl_results as (
    select
        month_start_date,
        id_group,
        id_clan,
        id_cwl_war,
        round_number,
        result,
        destruction_pct,
        attacks_available,
        attacks_used
    from {{ ref('fct_war_results') }}
    where war_type = 'cwl'
),

scored_cwl_attacks as (
    select
        id_cwl_war,
        id_attacker_clan,
        stars
    from {{ ref('fct_cwl_attacks') }}
    where stars is not null
),

attacks_by_war as (
    select
        id_cwl_war,
        id_attacker_clan,
        count(*) as scored_attacks,
        sum(stars) as attack_stars,
        count(case when stars = 3 then 1 end) as triples
    from scored_cwl_attacks
    group by id_cwl_war, id_attacker_clan
),

round_performance as (
    select
        w.month_start_date,
        w.id_group,
        w.id_clan,
        w.round_number,
        count(*) as wars_played,
        count(w.result) as wars_with_result,
        count(case when w.result = 'win' then 1 end) as wins,
        count(w.destruction_pct) as wars_with_destruction,
        sum(w.destruction_pct) as destruction_sum,
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
        and w.id_clan = a.id_attacker_clan
    group by w.month_start_date, w.id_group, w.id_clan, w.round_number
)

select * from round_performance