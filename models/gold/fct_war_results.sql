with cwl_war_clans as (
    select
        id_war_clan,
        id_cwl_war,
        id_group_clan,
        attacks_used,
        stars,
        destruction_pct,
        result
    from {{ ref('cwl_war_clans') }}
),

group_clans as (
    select
        id_group_clan,
        id_clan
    from {{ ref('group_clans') }}
),

cwl_wars as (
    select
        id_cwl_war,
        id_group,
        round_number,
        team_size,
        attacks_per_member
    from {{ ref('cwl_wars') }}
),

cwl_groups as (
    select
        id_group,
        id_season
    from {{ ref('cwl_groups') }}
),

cwl_seasons as (
    select
        id_season,
        month_start_date
    from {{ ref('cwl_seasons') }}
),

normal_wars as (
    select
        id_normal_war,
        id_clan_a,
        id_clan_b,
        attacks_used_a,
        attacks_used_b,
        stars_a,
        stars_b,
        destruction_pct_a,
        destruction_pct_b,
        result_a,
        end_time_utc,
        team_size,
        attacks_per_member,
        observed_a,
        observed_b
    from {{ ref('normal_wars') }}
    where observed_a or observed_b
),

cwl_sides as (
    select
        s.id_war_clan,
        s.id_cwl_war,
        g.id_clan,
        s.attacks_used,
        s.stars,
        s.destruction_pct,
        s.result
    from cwl_war_clans s
    inner join group_clans g
        on s.id_group_clan = g.id_group_clan
),

normal_sides as (
    select
        id_normal_war,
        id_clan_a as id_clan,
        id_clan_b as id_opponent_clan,
        attacks_used_a as attacks_used,
        stars_a as stars,
        destruction_pct_a as destruction_pct,
        result_a as result,
        end_time_utc,
        team_size,
        attacks_per_member
    from normal_wars
    where observed_a

    union all

    select
        id_normal_war,
        id_clan_b,
        id_clan_a,
        attacks_used_b,
        stars_b,
        destruction_pct_b,
        case result_a
            when 'win' then 'lose'
            when 'lose' then 'win'
            when 'tie' then 'tie'
        end as result,
        end_time_utc,
        team_size,
        attacks_per_member
    from normal_wars
    where observed_b
),

war_results as (
    select
        {{ coc_id('war_result', ["'cwl'", 's.id_war_clan']) }} as id_war_result,
        'cwl' as war_type,
        s.id_war_clan,
        null::number(20, 0) as id_normal_war,
        s.id_clan,
        rival.id_clan as id_opponent_clan,
        s.attacks_used,
        s.stars,
        s.destruction_pct,
        s.result,
        w.id_cwl_war,
        w.id_group,
        w.round_number,
        m.month_start_date,
        w.team_size,
        w.team_size * w.attacks_per_member as attacks_available
    from cwl_sides s
    inner join cwl_sides rival
        on s.id_cwl_war = rival.id_cwl_war and s.id_war_clan <> rival.id_war_clan
    inner join cwl_wars w on s.id_cwl_war = w.id_cwl_war
    inner join cwl_groups g on w.id_group = g.id_group
    inner join cwl_seasons m on g.id_season = m.id_season

    union all

    select
        {{ coc_id('war_result', ["'normal'", 'id_normal_war', 'id_clan']) }} as id_war_result,
        'normal' as war_type,
        null::number(20, 0) as id_war_clan,
        id_normal_war,
        id_clan,
        id_opponent_clan,
        attacks_used,
        stars,
        destruction_pct,
        result,
        null::number(20, 0) as id_cwl_war,
        null::number(20, 0) as id_group,
        null::integer as round_number,
        cast(date_trunc('month', convert_timezone('UTC', end_time_utc)) as date) as month_start_date,
        team_size,
        team_size * attacks_per_member as attacks_available
    from normal_sides
)

select * from war_results
