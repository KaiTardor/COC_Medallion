with participants as (
    select
        p.id_participation,
        p.id_player,
        p.town_hall_level,
        s.id_cwl_war,
        g.id_clan
    from {{ ref('cwl_war_participants') }} p
    inner join {{ ref('cwl_war_clans') }} s on p.id_war_clan = s.id_war_clan
    inner join {{ ref('group_clans') }} g on s.id_group_clan = g.id_group_clan
),

attacks as (
    select
        a.id_attack,
        a.id_cwl_war,
        a.attack_order,
        w.id_group,
        g.season,
        p.id_player as id_attacker,
        d.id_player as id_defender,
        p.id_clan as id_attacker_clan,
        d.id_clan as id_defender_clan,
        p.town_hall_level as attacker_th,
        d.town_hall_level as defender_th,
        a.matchup,
        a.stars,
        a.destruction_pct
    from {{ ref('attacks_defenses') }} a
    inner join participants p
        on a.id_attacker_participation = p.id_participation and a.id_cwl_war = p.id_cwl_war
    inner join participants d
        on a.id_defender_participation = d.id_participation and a.id_cwl_war = d.id_cwl_war
    inner join {{ ref('cwl_wars') }} w on a.id_cwl_war = w.id_cwl_war
    inner join {{ ref('dim_cwl_group') }} g on w.id_group = g.id_group
)

select * from attacks