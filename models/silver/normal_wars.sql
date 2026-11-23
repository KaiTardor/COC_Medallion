{{ config(
    materialized='incremental',
    incremental_strategy='coc_war_merge',
    unique_key='id_normal_war',
    on_schema_change='ignore',
    tmp_relation_type='table'
) }}

with war_inputs as (
    select
        id_normal_war,
        end_time_utc,
        clan_tag,
        clan_a_tag,
        id_clan,
        id_opponent_clan,
        team_size,
        attacks_per_member,
        war_id,
        attacks_used,
        stars,
        destruction_pct,
        payload,
        result
    from {{ ref('stg_normal_wars') }}
),

{{ coc_wars_to_process('id_normal_war', ['clan_tag', 'war_id', 'payload']) }},

captures as (
    select
        id_normal_war,
        convert_timezone('UTC', end_time_utc) as end_time_utc,
        clan_tag = clan_a_tag as from_a,
        iff(clan_tag = clan_a_tag, id_clan, id_opponent_clan) as id_clan_a,
        iff(clan_tag = clan_a_tag, id_opponent_clan, id_clan) as id_clan_b,
        team_size,
        attacks_per_member,
        war_id,
        attacks_used,
        stars,
        destruction_pct,
        payload:clan.expEarned::integer as exp_earned,
        payload:opponent.stars::integer as opponent_stars,
        payload:opponent.destructionPercentage::float as opponent_destruction_pct,
        result
    from selected_wars
),

wars as (
    select
        id_normal_war,
        end_time_utc,
        id_clan_a,
        id_clan_b,
        max(team_size) as team_size,
        max(attacks_per_member) as attacks_per_member,
        min(war_id) as war_id_source,
        boolor_agg(from_a) as observed_a,
        max(iff(from_a, attacks_used, null)) as attacks_used_a,
        coalesce(max(iff(from_a, stars, null)),
                 max(iff(not from_a, opponent_stars, null))) as stars_a,
        coalesce(max(iff(from_a, destruction_pct, null)),
                 max(iff(not from_a, opponent_destruction_pct, null))) as destruction_pct_a,
        max(iff(from_a, exp_earned, null)) as exp_earned_a,
        coalesce(
            max(iff(from_a, result, null)),
            max(iff(not from_a, case result
                when 'win' then 'lose'
                when 'lose' then 'win'
                when 'tie' then 'tie'
            end, null))
        ) as result_a,
        boolor_agg(not from_a) as observed_b,
        max(iff(not from_a, attacks_used, null)) as attacks_used_b,
        coalesce(max(iff(not from_a, stars, null)),
                 max(iff(from_a, opponent_stars, null))) as stars_b,
        coalesce(max(iff(not from_a, destruction_pct, null)),
                 max(iff(from_a, opponent_destruction_pct, null))) as destruction_pct_b,
        max(iff(not from_a, exp_earned, null)) as exp_earned_b
    from captures
    group by id_normal_war, end_time_utc, id_clan_a, id_clan_b
),

model_rows as (
    {{ coc_war_rows('wars', 'id_normal_war', 'id_normal_war') }}
)

select * from model_rows
