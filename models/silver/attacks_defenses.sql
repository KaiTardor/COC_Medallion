{{ config(
    materialized='incremental',
    incremental_strategy='coc_war_merge',
    unique_key='id_attack',
    on_schema_change='ignore',
    tmp_relation_type='table'
) }}

-- depends_on: {{ ref('cwl_war_participants') }}

with war_inputs as (
    select
        id_cwl_war,
        season,
        round_number,
        payload
    from {{ ref('stg_cwl_wars') }}
    where war_state = 'warEnded'
),

{{ coc_wars_to_process('id_cwl_war', ['payload']) }},

participants as (
    select id_cwl_war, id_participation, town_hall_level, attacks_payload
    from ({{ coc_war_participants('selected_wars', wars_are_finished=true) }}) as extracted_participants
),

attackers as (
    select id_cwl_war, id_participation, town_hall_level, attacks_payload
    from participants
    where array_size(attacks_payload) > 0
),

attack_rows as (
    select
        p.id_cwl_war,
        p.id_participation as id_attacker_participation,
        p.town_hall_level as attacker_th,
        {{ coc_id('player', ['a.value:defenderTag::varchar']) }} as id_defender_player,
        a.value:"order"::integer as attack_order,
        a.value:stars::integer as stars,
        a.value:destructionPercentage::float as destruction_pct,
        a.value:duration::integer as duration
    from attackers p,
        lateral flatten(input => p.attacks_payload) a
),

attack_ids as (
    select
        {{ coc_id('attack', ['id_cwl_war', 'attack_order']) }} as id_attack,
        id_cwl_war,
        id_attacker_participation,
        {{ coc_id('participation', ['id_cwl_war', 'id_defender_player']) }} as id_defender_participation,
        attacker_th,
        attack_order,
        stars,
        destruction_pct,
        duration
    from attack_rows
),

classified as (
    select
        a.id_attack,
        a.id_cwl_war,
        a.id_attacker_participation,
        a.id_defender_participation,
        a.attack_order,
        a.stars,
        a.destruction_pct,
        a.duration,
        case
            when a.attacker_th is null or d.town_hall_level is null then null
            when a.attacker_th > d.town_hall_level then 'down-hit'
            when a.attacker_th < d.town_hall_level then 'up-hit'
            else 'same-TH'
        end as matchup
    from attack_ids a
    left join participants d
        on a.id_defender_participation = d.id_participation
),

model_rows as (
    {{ coc_war_rows('classified', 'id_cwl_war', 'id_attack') }}
)

select * from model_rows
