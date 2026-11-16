with cwl_results as (
    select
        season, group_id, war_id, round_number, clan_tag,
        result, destruction_pct, attacks_available
    from {{ ref('war_results') }}
    where war_type = 'cwl'
),

cwl_groups as (
    select season, group_id, division_id
    from {{ ref('cwl_groups') }}
),

attacks as (
    select season, war_tag, attacker_clan_tag
    from {{ ref('attacks') }}
),

attacks_by_war as (
    select season, war_tag, attacker_clan_tag as clan_tag, count(*) as attacks_used
    from attacks
    group by season, war_tag, attacker_clan_tag
),

round_totals as (
    select
        w.season,
        w.group_id,
        g.division_id,
        w.clan_tag,
        w.round_number,
        count(*) as wars_played,
        count(w.result) as wars_with_result,
        count(case when w.result = 'win' then 1 end) as wins,
        count(w.destruction_pct) as wars_with_destruction,
        sum(w.destruction_pct) as destruction_sum,
        sum(w.attacks_available) as attacks_available,
        sum(coalesce(a.attacks_used, 0)) as attacks_used
    from cwl_results w
    left join cwl_groups g
        on w.season = g.season and w.group_id = g.group_id
    left join attacks_by_war a
        on w.season = a.season and w.war_id = a.war_tag and w.clan_tag = a.clan_tag
    group by w.season, w.group_id, g.division_id, w.clan_tag, w.round_number
),

running_totals as (
    select
        season, group_id, division_id, clan_tag, round_number,
        wars_played, wars_with_result, wins, wars_with_destruction,
        destruction_sum, attacks_available, attacks_used,
        sum(wars_played) over (
            partition by season, group_id, clan_tag order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_wars_played,
        sum(wars_with_result) over (
            partition by season, group_id, clan_tag order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_wars_with_result,
        sum(wins) over (
            partition by season, group_id, clan_tag order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_wins,
        sum(wars_with_destruction) over (
            partition by season, group_id, clan_tag order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_wars_with_destruction,
        sum(destruction_sum) over (
            partition by season, group_id, clan_tag order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_destruction_sum,
        sum(attacks_available) over (
            partition by season, group_id, clan_tag order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_attacks_available,
        sum(attacks_used) over (
            partition by season, group_id, clan_tag order by round_number
            rows between unbounded preceding and current row
        ) as cumulative_attacks_used
    from round_totals
),

metrics as (
    select
        season, group_id, division_id, clan_tag, round_number,
        wars_played, wars_with_result, wins, wars_with_destruction, destruction_sum,
        attacks_available, attacks_used,
        destruction_sum / nullif(wars_with_destruction, 0) as avg_destruction_pct,
        100.0 * attacks_used / nullif(attacks_available, 0) as attack_usage_pct,
        cumulative_wars_played, cumulative_wars_with_result, cumulative_wins,
        cumulative_wars_with_destruction, cumulative_destruction_sum,
        cumulative_attacks_available, cumulative_attacks_used,
        100.0 * cumulative_wins / nullif(cumulative_wars_with_result, 0)
            as cumulative_win_rate_pct,
        cumulative_destruction_sum / nullif(cumulative_wars_with_destruction, 0)
            as cumulative_avg_destruction_pct,
        100.0 * cumulative_attacks_used / nullif(cumulative_attacks_available, 0)
            as cumulative_attack_usage_pct
    from running_totals
)

select *
from metrics
