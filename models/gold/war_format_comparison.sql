with war_results as (
    select season, id_clan, war_type, result, destruction_pct,
        attacks_used, attacks_available
    from {{ ref('fct_war_results') }}
    where war_type in ('cwl', 'normal')
),

format_totals as (
    select
        season,
        id_clan,
        war_type,
        count(*) as wars_played,
        count(result) as wars_with_result,
        count(case when result = 'win' then 1 end) as wins,
        avg(destruction_pct) as avg_destruction_pct,
        sum(case
            when attacks_used is not null and attacks_available > 0
            then attacks_used
        end) as attacks_used,
        sum(case
            when attacks_used is not null and attacks_available > 0
            then attacks_available
        end) as attacks_available
    from war_results
    group by season, id_clan, war_type
),

format_metrics as (
    select
        season,
        id_clan,
        war_type,
        wars_played,
        avg_destruction_pct,
        100.0 * wins / nullif(wars_with_result, 0) as win_rate_pct,
        100.0 * attacks_used / nullif(attacks_available, 0) as attack_usage_pct
    from format_totals
),

comparison as (
    select
        c.season,
        cl.clan_tag,
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
        c.id_clan
    from format_metrics c
    inner join format_metrics n
        on c.season = n.season
        and c.id_clan = n.id_clan
        and n.war_type = 'normal'
    left join {{ ref('dim_clan') }} cl on c.id_clan = cl.id_clan
    where c.war_type = 'cwl'
)

select * from comparison