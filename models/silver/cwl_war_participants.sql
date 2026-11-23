{{ config(
    materialized='incremental',
    incremental_strategy='coc_war_merge',
    unique_key='id_participation',
    on_schema_change='ignore',
    tmp_relation_type='table'
) }}

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
    select
        id_participation,
        id_cwl_war,
        id_war_clan,
        id_player,
        town_hall_level,
        map_position,
        coalesce(array_size(attacks_payload), 0) as attacks_used,
        attacks_received,
        player_name as player_name_observed
    from ({{ coc_war_participants('selected_wars', wars_are_finished=true) }}) as extracted_participants
),

model_rows as (
    {{ coc_war_rows('participants', 'id_cwl_war', 'id_participation') }}
)

select * from model_rows
