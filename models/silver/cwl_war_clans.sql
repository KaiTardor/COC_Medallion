{{ config(
    materialized='incremental',
    incremental_strategy='coc_war_merge',
    unique_key='id_war_clan',
    on_schema_change='ignore',
    tmp_relation_type='table'
) }}

with finished_wars as (
    select
        id_cwl_war,
        id_group,
        payload:clan as clan,
        payload:opponent as opponent
    from {{ ref('stg_cwl_wars') }}
    where war_state = 'warEnded'
),

sides as (
    select id_cwl_war, id_group, clan, opponent as rival
    from finished_wars

    union all

    select id_cwl_war, id_group, opponent as clan, clan as rival
    from finished_wars
),

scores as (
    select
        id_cwl_war,
        id_group,
        {{ coc_id('clan', ['clan:tag::varchar']) }} as id_clan,
        clan:attacks::integer as attacks_used,
        clan:stars::integer as stars,
        rival:stars::integer as opponent_stars,
        clan:destructionPercentage::float as destruction_pct,
        rival:destructionPercentage::float as opponent_destruction_pct
    from sides
),

war_inputs as (
    select
        {{ coc_id('clan_war', ['s.id_cwl_war', 's.id_clan']) }} as id_war_clan,
        s.id_cwl_war,
        g.id_group_clan,
        s.attacks_used,
        s.stars,
        s.destruction_pct,
        s.opponent_stars,
        s.opponent_destruction_pct
    from scores s
    left join {{ ref('group_clans') }} g
        on s.id_group = g.id_group and s.id_clan = g.id_clan
),

{{ coc_wars_to_process('id_cwl_war', [
    'id_war_clan', 'id_group_clan', 'attacks_used', 'stars',
    'destruction_pct', 'opponent_stars', 'opponent_destruction_pct'
]) }},

war_clans as (
    select
        s.id_war_clan,
        s.id_cwl_war,
        s.id_group_clan,
        s.attacks_used,
        s.stars,
        s.destruction_pct,
        case
            when s.stars is null or s.opponent_stars is null then null
            when s.stars > s.opponent_stars then 'win'
            when s.stars < s.opponent_stars then 'lose'
            when s.destruction_pct is null or s.opponent_destruction_pct is null then null
            when s.destruction_pct > s.opponent_destruction_pct then 'win'
            when s.destruction_pct < s.opponent_destruction_pct then 'lose'
            else 'tie'
        end as result
    from selected_wars s
),

model_rows as (
    {{ coc_war_rows('war_clans', 'id_cwl_war', 'id_war_clan') }}
)

select * from model_rows