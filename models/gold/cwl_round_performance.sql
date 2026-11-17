with cwl_results as (
    select season, id_group, id_clan, round_number, result,
        destruction_pct, attacks_available, attacks_used
    from {{ ref('fct_war_results') }}
    where war_type = 'cwl'
),

round_totals as (
    select
        w.season,
        w.id_group,
        w.id_clan,
        w.round_number,
        count(*) as wars_played,
        count(w.result) as wars_with_result,
        count(case when w.result = 'win' then 1 end) as wins,
        count(w.destruction_pct) as wars_with_destruction,
        sum(w.destruction_pct) as destruction_sum,
        sum(case
            when w.attacks_used is not null and w.attacks_available > 0
            then w.attacks_available
        end) as attacks_available,
        sum(case
            when w.attacks_used is not null and w.attacks_available > 0
            then w.attacks_used
        end) as attacks_used
    from cwl_results w
    group by w.season, w.id_group, w.id_clan, w.round_number
),

running_totals as (
    select
        round_totals.*,
        sum(wars_played) over (
            partition by id_group, id_clan order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_wars_played,
        sum(wars_with_result) over (
            partition by id_group, id_clan order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_wars_with_result,
        sum(wins) over (
            partition by id_group, id_clan order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_wins,
        sum(wars_with_destruction) over (
            partition by id_group, id_clan order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_wars_with_destruction,
        sum(destruction_sum) over (
            partition by id_group, id_clan order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_destruction_sum,
        sum(attacks_available) over (
            partition by id_group, id_clan order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_attacks_available,
        sum(attacks_used) over (
            partition by id_group, id_clan order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_attacks_used
    from round_totals
),

metrics as (
    select
        t.season,
        g.group_id,
        g.division_id,
        c.clan_tag,
        t.round_number,
        t.wars_played,
        t.wars_with_result,
        t.wins,
        t.wars_with_destruction,
        t.destruction_sum,
        t.attacks_available,
        t.attacks_used,
        t.destruction_sum / nullif(t.wars_with_destruction, 0) as avg_destruction_pct,
        100.0 * t.attacks_used / nullif(t.attacks_available, 0) as attack_usage_pct,
        t.cumulative_wars_played,
        t.cumulative_wars_with_result,
        t.cumulative_wins,
        t.cumulative_wars_with_destruction,
        t.cumulative_destruction_sum,
        t.cumulative_attacks_available,
        t.cumulative_attacks_used,
        100.0 * t.cumulative_wins / nullif(t.cumulative_wars_with_result, 0)
            as cumulative_win_rate_pct,
        t.cumulative_destruction_sum / nullif(t.cumulative_wars_with_destruction, 0)
            as cumulative_avg_destruction_pct,
        100.0 * t.cumulative_attacks_used / nullif(t.cumulative_attacks_available, 0)
            as cumulative_attack_usage_pct,
        t.id_group,
        g.id_division,
        t.id_clan
    from running_totals t
    left join {{ ref('dim_cwl_group') }} g on t.id_group = g.id_group
    left join {{ ref('dim_clan') }} c on t.id_clan = c.id_clan
)

select * from metrics