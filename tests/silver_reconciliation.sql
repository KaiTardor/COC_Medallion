with lineups as (
    select id_war_clan, count(*) as players, sum(attacks_used) as expected_attacks
    from {{ ref('cwl_war_participants') }}
    group by id_war_clan
),

attacks as (
    select p.id_war_clan, count(*) as actual_attacks
    from {{ ref('attacks_defenses') }} a
    inner join {{ ref('cwl_war_participants') }} p
        on a.id_attacker_participation = p.id_participation
    group by p.id_war_clan
),

counts as (
    select
        s.id_cwl_war,
        s.id_war_clan,
        w.team_size,
        coalesce(l.players, 0) as players,
        s.attacks_used as scoreboard_attacks,
        coalesce(l.expected_attacks, 0) as lineup_attacks,
        coalesce(a.actual_attacks, 0) as actual_attacks
    from {{ ref('cwl_war_clans') }} s
    inner join {{ ref('cwl_wars') }} w on s.id_cwl_war = w.id_cwl_war
    left join lineups l on s.id_war_clan = l.id_war_clan
    left join attacks a on s.id_war_clan = a.id_war_clan
),

mismatches as (
    select * from counts
    where players is distinct from team_size
       or actual_attacks <> lineup_attacks
       or (scoreboard_attacks is not null and actual_attacks <> scoreboard_attacks)
)

select * from mismatches
