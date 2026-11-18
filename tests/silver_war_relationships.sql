with sides as (
    select id_clan_war, id_cwl_war, id_clan, id_opponent_clan
    from {{ ref('clan_wars') }}
),

participants as (
    select id_participation, id_cwl_war, id_clan
    from {{ ref('cwl_war_participants') }}
),

attacks as (
    select id_attack, id_cwl_war, id_attacker_participation, id_defender_participation
    from {{ ref('attacks_defenses') }}
),

results as (
    select id_war_result, war_type, id_clan_war, id_normal_war, id_clan
    from {{ ref('war_results') }}
),

issues as (
    select 'cwl_sides' as issue, w.id_cwl_war as id
    from {{ ref('cwl_wars') }} w
    left join sides s on w.id_cwl_war = s.id_cwl_war
    group by w.id_cwl_war
    having count(distinct s.id_clan) <> 2

    union all

    select 'cwl_side_outside_group', s.id_clan_war
    from sides s
    inner join {{ ref('cwl_wars') }} w
        on s.id_cwl_war = w.id_cwl_war
    left join {{ ref('group_clans') }} g
        on w.id_group = g.id_group and s.id_clan = g.id_clan
    where g.id_group_clan is null or s.id_clan = s.id_opponent_clan

    union all

    select 'participant_without_side', p.id_participation
    from participants p
    left join sides s
        on p.id_cwl_war = s.id_cwl_war and p.id_clan = s.id_clan
    where s.id_clan_war is null

    union all

    select 'attack_participants_mismatch', a.id_attack
    from attacks a
    left join participants p
        on a.id_attacker_participation = p.id_participation
    left join participants d
        on a.id_defender_participation = d.id_participation
    where p.id_participation is null
       or d.id_participation is null
       or a.id_cwl_war <> p.id_cwl_war
       or a.id_cwl_war <> d.id_cwl_war
       or p.id_clan = d.id_clan

    union all

    select 'repeated_cwl_attacker', id_attacker_participation
    from attacks
    group by id_attacker_participation
    having count(*) > 1

    union all

    select 'invalid_cwl_result', r.id_war_result
    from results r
    left join sides s on r.id_clan_war = s.id_clan_war
    where r.war_type = 'cwl'
      and (
          r.id_normal_war is not null
          or s.id_clan_war is null
          or r.id_clan is distinct from s.id_clan
      )

    union all

    select 'invalid_normal_result', r.id_war_result
    from results r
    left join {{ ref('normal_wars') }} w
        on r.id_normal_war = w.id_normal_war
    where r.war_type = 'normal'
      and (
          r.id_clan_war is not null
          or w.id_normal_war is null
          or r.id_clan is null
          or (r.id_clan is distinct from w.id_clan_a and r.id_clan is distinct from w.id_clan_b)
      )
)

select * from issues