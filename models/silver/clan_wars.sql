with cwl_wars as (
    select
        season,
        group_id,
        war_tag,
        round_number,
        team_size,
        payload:clan as clan,
        payload:opponent as opponent
    from {{ ref('stg_cwl_wars') }}
    where war_state = 'warEnded'
),

sides as (
    select
        season, group_id, war_tag, round_number, team_size,
        clan, opponent as rival
    from cwl_wars

    union all

    select
        season, group_id, war_tag, round_number, team_size,
        opponent as clan, clan as rival
    from cwl_wars
),

scores as (
    select
        season,
        group_id,
        war_tag,
        round_number,
        team_size,
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
        season,
        group_id,
        war_tag,
        round_number,
        team_size,
        clan_tag,
        opponent_tag,
        attacks_used,
        stars,
        opponent_stars,
        destruction_pct,
        opponent_destruction_pct,
        team_size as attacks_available,
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