with cwl_wars as (
    select war_tag, team_size
    from {{ ref('cwl_wars') }}
),

lineups as (
    select
        war_tag,
        count(*) as players,
        sum(attacks_used) as expected_attacks
    from {{ ref('cwl_war_participants') }}
    group by war_tag
),

attacks as (
    select war_tag, count(*) as actual_attacks
    from {{ ref('attacks') }}
    group by war_tag
),

mismatches as (
    select
        'cwl_lineup_size' as issue, w.war_tag,
        2 * w.team_size as expected_count, coalesce(l.players, 0) as actual_count
    from cwl_wars w
    left join lineups l on w.war_tag = l.war_tag
    where coalesce(l.players, 0) <> 2 * w.team_size or w.team_size is null

    union all

    select
        'cwl_attack_count', l.war_tag,
        l.expected_attacks, coalesce(a.actual_attacks, 0)
    from lineups l
    left join attacks a on l.war_tag = a.war_tag
    where coalesce(a.actual_attacks, 0) <> l.expected_attacks
)

select *
from mismatches
