with staging as (
    select
        season,
        war_id,
        end_time_utc,
        clan_tag,
        opponent_tag,
        team_size,
        attacks_per_member
    from {{ ref('stg_normal_wars') }}
),

wars as (
    select distinct
        season,
        war_id,
        end_time_utc,
        least(clan_tag, opponent_tag) as clan_a_tag,
        greatest(clan_tag, opponent_tag) as clan_b_tag,
        team_size,
        attacks_per_member
    from staging
)

select * from wars