with war_results as (
    select
        month_start_date,
        id_clan,
        war_type,
        result,
        destruction_pct,
        attacks_used,
        attacks_available
    from {{ ref('fct_war_results') }}
    where war_type in ('cwl', 'normal')
),

normal_coverage as (
    select
        to_date(season || '-01', 'YYYY-MM-DD') as month_start_date,
        id_clan,
        coverage_status
    from {{ ref('normal_war_coverage') }}
),

format_totals as (
    select
        month_start_date,
        id_clan,
        war_type,
        count(*) as wars_played,
        count(result) as wars_with_result,
        count(case when result = 'win' then 1 end) as wins,
        count(destruction_pct) as wars_with_destruction,
        sum(destruction_pct) as destruction_sum,
        sum(case
            when attacks_used is not null and attacks_available > 0
            then attacks_used
        end) as attacks_used,
        sum(case
            when attacks_used is not null and attacks_available > 0
            then attacks_available
        end) as attacks_available
    from war_results
    group by month_start_date, id_clan, war_type
),

format_metrics as (
    select
        month_start_date,
        id_clan,
        war_type,
        wars_played,
        wars_with_result,
        wins,
        wars_with_destruction,
        destruction_sum,
        attacks_used,
        attacks_available,
        destruction_sum / nullif(wars_with_destruction, 0) as avg_destruction_pct,
        100.0 * wins / nullif(wars_with_result, 0) as win_rate_pct,
        100.0 * attacks_used / nullif(attacks_available, 0) as attack_usage_pct
    from format_totals
),

comparison as (
    select
        c.month_start_date,
        c.id_clan,
        c.wars_played as cwl_wars_played,
        n.wars_played as normal_wars_played,
        c.win_rate_pct as cwl_win_rate_pct,
        n.win_rate_pct as normal_win_rate_pct,
        c.win_rate_pct - n.win_rate_pct as win_rate_diff_pp,
        c.avg_destruction_pct as cwl_avg_destruction_pct,
        n.avg_destruction_pct as normal_avg_destruction_pct,
        c.avg_destruction_pct - n.avg_destruction_pct as destruction_diff_pp,
        c.attack_usage_pct as cwl_attack_usage_pct,
        n.attack_usage_pct as normal_attack_usage_pct,
        c.attack_usage_pct - n.attack_usage_pct as attack_usage_diff_pp,
        c.wins as cwl_wins,
        n.wins as normal_wins,
        c.wars_with_result as cwl_wars_with_result,
        n.wars_with_result as normal_wars_with_result,
        c.wars_with_destruction as cwl_wars_with_destruction,
        n.wars_with_destruction as normal_wars_with_destruction,
        c.destruction_sum as cwl_destruction_sum,
        n.destruction_sum as normal_destruction_sum,
        c.attacks_used as cwl_attacks_used,
        n.attacks_used as normal_attacks_used,
        c.attacks_available as cwl_attacks_available,
        n.attacks_available as normal_attacks_available,
        cov.coverage_status as normal_coverage_status
    from format_metrics c
    inner join format_metrics n
        on c.month_start_date = n.month_start_date
        and c.id_clan = n.id_clan
        and n.war_type = 'normal'
    left join normal_coverage cov
        on n.month_start_date = cov.month_start_date
        and n.id_clan = cov.id_clan
    where c.war_type = 'cwl'
)

select * from comparison