with cwl_sides as (
    select
        s.id_war_clan,
        s.id_cwl_war,
        g.id_clan,
        s.attacks_used,
        s.stars,
        s.destruction_pct,
        s.result
    from {{ ref('cwl_war_clans') }} s
    inner join {{ ref('group_clans') }} g
        on s.id_group_clan = g.id_group_clan
),

cwl as (
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
        g.season,
        w.team_size,
        w.team_size * w.attacks_per_member as attacks_available
    from cwl_sides s
    inner join cwl_sides rival
        on s.id_cwl_war = rival.id_cwl_war and s.id_war_clan <> rival.id_war_clan
    inner join {{ ref('cwl_wars') }} w on s.id_cwl_war = w.id_cwl_war
    inner join {{ ref('dim_cwl_group') }} g on w.id_group = g.id_group
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
    from {{ ref('normal_wars') }}
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
    from {{ ref('normal_wars') }}
    where observed_b
),

normal as (
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
        to_char(end_time_utc, 'YYYY-MM') as season,
        team_size,
        team_size * attacks_per_member as attacks_available
    from normal_sides
),

combined as (
    select * from cwl
    union all
    select * from normal
)

select * from combined