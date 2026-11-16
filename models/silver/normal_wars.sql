with staging as (
    select
        id_normal_war,
        war_id,
        end_time_utc,
        clan_tag,
        clan_a_tag,
        id_clan,
        id_opponent_clan,
        team_size,
        attacks_per_member
    from {{ ref('stg_normal_wars') }}
),

wars as (
    select distinct
        id_normal_war,
        convert_timezone('UTC', end_time_utc) as end_time_utc,
        case when clan_tag = clan_a_tag then id_clan else id_opponent_clan end as id_clan_a,
        case when clan_tag = clan_a_tag then id_opponent_clan else id_clan end as id_clan_b,
        team_size,
        attacks_per_member,
        min(war_id) over (partition by id_normal_war) as war_id_source
    from staging
)

select * from wars