with cwl as (
    select
        season,
        'cwl' as war_type,
        war_tag as war_id,
        group_id,
        round_number,
        clan_tag,
        opponent_tag,
        team_size,
        attacks_used,
        attacks_available,
        stars,
        destruction_pct,
        result
    from {{ ref('clan_wars') }}
),

normal as (
    select
        season,
        'normal' as war_type,
        war_id,
        null::varchar as group_id,
        null::integer as round_number,
        clan_tag,
        opponent_tag,
        team_size,
        attacks_used,
        team_size * attacks_per_member as attacks_available,
        stars,
        destruction_pct,
        result
    from {{ ref('stg_normal_wars') }}
),

combined as (
    select
        season, 
        war_type, 
        war_id, 
        group_id, 
        round_number, 
        clan_tag,
        opponent_tag, 
        team_size, 
        attacks_used, 
        attacks_available,
        stars, 
        destruction_pct, 
        result
    from cwl

    union all

    select
        season, 
        war_type, 
        war_id, 
        group_id, 
        round_number, 
        clan_tag,
        opponent_tag, 
        team_size, 
        attacks_used, 
        attacks_available,
        stars, 
        destruction_pct, 
        result
    from normal
)

select * from combined