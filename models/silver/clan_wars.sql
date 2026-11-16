with wars as (
    select
        id_cwl_war,
        payload:clan as clan,
        payload:opponent as opponent
    from {{ ref('stg_cwl_wars') }}
    where war_state = 'warEnded'
),

sides as (
    select id_cwl_war, clan, opponent as rival
    from wars

    union all

    select id_cwl_war, opponent as clan, clan as rival
    from wars
),

scores as (
    select
        id_cwl_war,
        clan:tag::varchar as clan_tag,
        rival:tag::varchar as opponent_tag,
        clan:attacks::integer as attacks_used,
        clan:stars::integer as stars,
        rival:stars::integer as opponent_stars,
        clan:destructionPercentage::float as destruction_pct,
        rival:destructionPercentage::float as opponent_destruction_pct
    from sides
),

with_results as (
    select
        {{ coc_id('clan', ['clan_tag']) }} as id_clan,
        {{ coc_id('clan', ['opponent_tag']) }} as id_opponent_clan,
        {{ coc_id('clan_war', ['id_cwl_war', 'id_clan']) }} as id_clan_war,
        id_cwl_war,
        attacks_used,
        stars,
        opponent_stars,
        destruction_pct,
        opponent_destruction_pct,
        case
            when stars is null or opponent_stars is null then null
            when stars > opponent_stars then 'win'
            when stars < opponent_stars then 'lose'
            when destruction_pct is null or opponent_destruction_pct is null then null
            when destruction_pct > opponent_destruction_pct then 'win'
            when destruction_pct < opponent_destruction_pct then 'lose'
            else 'tie'
        end as result
    from scores
)

select * from with_results