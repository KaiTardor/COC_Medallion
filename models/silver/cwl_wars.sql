with staging as (
    select
        season,
        group_id,
        war_tag,
        round_number,
        team_size,
        clan_tag,
        opponent_tag
    from {{ ref('stg_cwl_wars') }}
    where war_state = 'warEnded'
),

wars as (
    select
        season,
        group_id,
        war_tag,
        round_number,
        team_size,
        clan_tag,
        opponent_tag,
        1 as attacks_per_member
    from staging
)

select * from wars