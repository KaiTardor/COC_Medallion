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
    select id_cwl_war, count(*) as actual_attacks
    from {{ ref('attacks_defenses') }}
    group by id_cwl_war
),

mismatches as (
    select
        'cwl_lineup_size' as issue,
        w.id_cwl_war,
        2 * w.team_size as expected_count,
        coalesce(l.players, 0) as actual_count
    from cwl_wars w
    left join lineups l on w.id_cwl_war = l.id_cwl_war
    where coalesce(l.players, 0) <> 2 * w.team_size
       or w.team_size is null

    union all

    select
        'cwl_attack_count',
        l.id_cwl_war,
        l.expected_attacks,
        coalesce(a.actual_attacks, 0)
    from lineups l
    left join attacks a on l.id_cwl_war = a.id_cwl_war
    where coalesce(a.actual_attacks, 0) <> l.expected_attacks
)

select * from mismatches