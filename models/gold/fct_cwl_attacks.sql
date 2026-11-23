{{ config(
    materialized='incremental',
    incremental_strategy='coc_war_merge',
    unique_key='id_attack',
    on_schema_change='ignore',
    tmp_relation_type='table'
) }}

with attack_events as (
    select
        id_attack,
        id_cwl_war,
        attack_order,
        id_attacker_participation,
        id_defender_participation,
        matchup,
        stars,
        destruction_pct
    from {{ ref('attacks_defenses') }}
),

cwl_war_participants as (
    select
        id_participation,
        id_war_clan,
        id_player,
        town_hall_level
    from {{ ref('cwl_war_participants') }}
),

cwl_war_clans as (
    select
        id_war_clan,
        id_cwl_war,
        id_group_clan
    from {{ ref('cwl_war_clans') }}
),

group_clans as (
    select
        id_group_clan,
        id_clan
    from {{ ref('group_clans') }}
),

cwl_wars as (
    select
        id_cwl_war,
        id_group
    from {{ ref('cwl_wars') }}
),

cwl_groups as (
    select
        id_group,
        id_season
    from {{ ref('cwl_groups') }}
),

cwl_seasons as (
    select
        id_season,
        month_start_date
    from {{ ref('cwl_seasons') }}
),

participants as (
    select
        p.id_participation,
        p.id_player,
        p.town_hall_level,
        s.id_cwl_war,
        g.id_clan
    from cwl_war_participants p
    inner join cwl_war_clans s on p.id_war_clan = s.id_war_clan
    inner join group_clans g on s.id_group_clan = g.id_group_clan
),

war_details as (
    select w.id_cwl_war, w.id_group, m.month_start_date
    from cwl_wars w
    inner join cwl_groups g on w.id_group = g.id_group
    inner join cwl_seasons m on g.id_season = m.id_season
),

-- Compare each input before joining each attack to its two participants.
war_inputs as (
    select
        id_cwl_war,
        'attack' as input_type,
        hash(id_attack, attack_order, id_attacker_participation, id_defender_participation,
             matchup, stars, destruction_pct) as input_hash
    from attack_events

    union all

    select
        id_cwl_war,
        'participant',
        hash(id_participation, id_player, town_hall_level, id_clan)
    from participants

    union all

    select
        id_cwl_war,
        'war',
        hash(id_group, month_start_date)
    from war_details
),

{{ coc_wars_to_process('id_cwl_war', ['input_type', 'input_hash']) }},

selected_attacks as (
    select a.*
    from attack_events a
    where exists (
        select 1
        from selected_wars w
        where w.id_cwl_war = a.id_cwl_war
    )
),

attacks as (
    select
        a.id_attack,
        a.id_cwl_war,
        a.attack_order,
        w.id_group,
        w.month_start_date,
        p.id_player as id_attacker,
        d.id_player as id_defender,
        p.id_clan as id_attacker_clan,
        d.id_clan as id_defender_clan,
        p.town_hall_level as attacker_th,
        d.town_hall_level as defender_th,
        a.matchup,
        a.stars,
        a.destruction_pct
    from selected_attacks a
    inner join participants p
        on a.id_attacker_participation = p.id_participation and a.id_cwl_war = p.id_cwl_war
    inner join participants d
        on a.id_defender_participation = d.id_participation and a.id_cwl_war = d.id_cwl_war
    inner join war_details w on a.id_cwl_war = w.id_cwl_war
),

model_rows as (
    {{ coc_war_rows('attacks', 'id_cwl_war', 'id_attack') }}
)

select * from model_rows