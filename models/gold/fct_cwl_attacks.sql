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
inner join {{ ref('cwl_war_participants') }} p
    on a.id_attacker_participation = p.id_participation
inner join {{ ref('cwl_war_participants') }} d
    on a.id_defender_participation = d.id_participation
inner join {{ ref('cwl_wars') }} w
    on a.id_cwl_war = w.id_cwl_war
inner join {{ ref('dim_cwl_group') }} g
    on w.id_group = g.id_group