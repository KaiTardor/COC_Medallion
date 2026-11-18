with cwl_wars as (
    select id_cwl_war, team_size
    from {{ ref('cwl_wars') }}
),

lineups as (
    select
        id_cwl_war,
        count(*) as players,
        sum(attacks_used) as expected_attacks
    from {{ ref('cwl_war_participants') }}
    group by id_cwl_war
),

attacks as (
    select
        id_cwl_war,
        count(*) as actual_attacks
    from {{ ref('attacks_defenses') }}
    group by id_cwl_war
),

attacks_by_clan as (
    select
        a.id_cwl_war,
        p.id_clan,
        count(*) as actual_attacks
    from {{ ref('attacks_defenses') }} a
    inner join {{ ref('cwl_war_participants') }} p
        on a.id_attacker_participation = p.id_participation
        and a.id_cwl_war = p.id_cwl_war
    group by a.id_cwl_war, p.id_clan
),

mismatches as (
    select
        'cwl_lineup_size' as issue,
        w.id_cwl_war,
        null as id_clan,
        2 * w.team_size as expected_count,
        coalesce(l.players, 0) as actual_count
    from cwl_wars w
    left join lineups l on w.id_cwl_war = l.id_cwl_war
    where coalesce(l.players, 0) <> 2 * w.team_size
       or w.team_size is null

    union all

    select
        'cwl_attack_count' as issue,
        l.id_cwl_war,
        null as id_clan,
        l.expected_attacks as expected_count,
        coalesce(a.actual_attacks, 0) as actual_count
    from lineups l
    left join attacks a on l.id_cwl_war = a.id_cwl_war
    where coalesce(a.actual_attacks, 0) <> l.expected_attacks

    union all

    select
        'cwl_clan_attack_count' as issue,
        s.id_cwl_war,
        s.id_clan,
        s.attacks_used as expected_count,
        coalesce(a.actual_attacks, 0) as actual_count
    from {{ ref('clan_wars') }} s
    left join attacks_by_clan a
        on s.id_cwl_war = a.id_cwl_war
        and s.id_clan = a.id_clan
    where s.attacks_used is not null
      and s.attacks_used <> coalesce(a.actual_attacks, 0)
)

select * from mismatches