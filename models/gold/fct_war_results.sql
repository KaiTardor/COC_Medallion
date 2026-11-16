with results as (
    select *
    from {{ ref('war_results') }}
),

cwl as (
    select
        r.*,
        w.id_cwl_war,
        w.id_group,
        w.round_number,
        g.season,
        w.team_size,
        w.team_size * w.attacks_per_member as attacks_available
    from results r
    inner join {{ ref('clan_wars') }} s
        on r.id_clan_war = s.id_clan_war
    inner join {{ ref('cwl_wars') }} w
        on s.id_cwl_war = w.id_cwl_war
    inner join {{ ref('dim_cwl_group') }} g
        on w.id_group = g.id_group
    where r.war_type = 'cwl'
),

normal as (
    select
        r.*,
        null::varchar as id_cwl_war,
        null::varchar as id_group,
        null::integer as round_number,
        to_char(w.end_time_utc, 'YYYY-MM') as season,
        w.team_size,
        w.team_size * w.attacks_per_member as attacks_available
    from results r
    inner join {{ ref('normal_wars') }} w
        on r.id_normal_war = w.id_normal_war
    where r.war_type = 'normal'
)

select * from cwl
union all
select * from normal