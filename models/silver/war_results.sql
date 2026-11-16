with cwl as (
    select
        {{ coc_id('war_result', ["'cwl'", 's.id_clan_war']) }} as id_war_result,
        'cwl' as war_type,
        s.id_clan_war,
        null::varchar as id_normal_war,
        s.id_clan,
        s.id_opponent_clan,
        s.attacks_used,
        s.stars,
        s.destruction_pct,
        s.result
    from {{ ref('clan_wars') }} s
),

normal as (
    select
        {{ coc_id('war_result', ["'normal'", 'id_normal_war', 'id_clan']) }} as id_war_result,
        'normal' as war_type,
        null::varchar as id_clan_war,
        id_normal_war,
        id_clan,
        id_opponent_clan,
        attacks_used,
        stars,
        destruction_pct,
        result
    from {{ ref('stg_normal_wars') }}
),

combined as (
    select * from cwl
    union all
    select * from normal
)

select * from combined