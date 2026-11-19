with sides as (
    select s.id_war_clan, s.id_cwl_war, g.id_clan, g.id_group
    from {{ ref('cwl_war_clans') }} s
    left join {{ ref('group_clans') }} g on s.id_group_clan = g.id_group_clan
),

participants as (
    select p.id_participation, p.id_player, s.id_cwl_war, s.id_war_clan
    from {{ ref('cwl_war_participants') }} p
    inner join sides s on p.id_war_clan = s.id_war_clan
),

issues as (
    select 'cwl_sides' as issue, w.id_cwl_war as id
    from {{ ref('cwl_wars') }} w
    left join sides s on w.id_cwl_war = s.id_cwl_war
    group by w.id_cwl_war
    having count(s.id_war_clan) <> 2 or count(distinct s.id_clan) <> 2

    union all

    select 'cwl_side_outside_group', s.id_war_clan
    from sides s
    inner join {{ ref('cwl_wars') }} w on s.id_cwl_war = w.id_cwl_war
    where s.id_group is distinct from w.id_group

    union all

    select 'player_repeated_in_war', min(id_participation)
    from participants
    group by id_cwl_war, id_player
    having count(*) > 1

    union all

    select 'attack_participants_mismatch', a.id_attack
    from {{ ref('attacks_defenses') }} a
    left join participants p on a.id_attacker_participation = p.id_participation
    left join participants d on a.id_defender_participation = d.id_participation
    where a.id_cwl_war is distinct from p.id_cwl_war
       or a.id_cwl_war is distinct from d.id_cwl_war
       or p.id_war_clan = d.id_war_clan

    union all

    select 'normal_war_observation', id_normal_war
    from {{ ref('normal_wars') }}
    where not (observed_a or observed_b)
       or id_clan_a = id_clan_b
       or (not observed_a and (attacks_used_a is not null or exp_earned_a is not null))
       or (not observed_b and (attacks_used_b is not null or exp_earned_b is not null))
)

select * from issues
