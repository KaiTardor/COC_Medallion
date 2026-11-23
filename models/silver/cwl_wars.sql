{{ config(
    materialized='incremental',
    incremental_strategy='coc_war_merge',
    unique_key='id_cwl_war',
    on_schema_change='ignore',
    tmp_relation_type='table'
) }}

with war_inputs as (
    select
        id_cwl_war,
        id_group,
        war_tag,
        round_number,
        team_size
    from {{ ref('stg_cwl_wars') }}
    where war_state = 'warEnded'
),

{{ coc_wars_to_process('id_cwl_war', ['id_group', 'war_tag', 'round_number', 'team_size']) }},

wars as (
    select
        id_cwl_war,
        id_group,
        war_tag,
        round_number,
        team_size,
        1 as attacks_per_member
    from selected_wars
),

model_rows as (
    {{ coc_war_rows('wars', 'id_cwl_war', 'id_cwl_war') }}
)

select * from model_rows
