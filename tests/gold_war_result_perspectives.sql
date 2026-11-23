with expected as (
    select
        'cwl' as war_type,
        s.id_cwl_war as id_war,
        g.id_clan,
        s.id_war_clan
    from {{ ref('cwl_war_clans') }} s
    inner join {{ ref('group_clans') }} g on s.id_group_clan = g.id_group_clan

    union all

    select 'normal', id_normal_war, id_clan_a, null::number(20, 0)
    from {{ ref('normal_wars') }}
    where observed_a

    union all

    select 'normal', id_normal_war, id_clan_b, null::number(20, 0)
    from {{ ref('normal_wars') }}
    where observed_b
),

actual as (
    select
        war_type,
        case when war_type = 'cwl' then id_cwl_war else id_normal_war end as id_war,
        id_clan,
        id_war_clan,
        count(*) as result_rows,
        count(id_cwl_war) + count(id_normal_war) as war_ids
    from {{ ref('fct_war_results') }}
    group by war_type, case when war_type = 'cwl' then id_cwl_war else id_normal_war end, id_clan, id_war_clan
),

issues as (
    select
        coalesce(e.war_type, a.war_type) as war_type,
        coalesce(e.id_war, a.id_war) as id_war,
        coalesce(e.id_clan, a.id_clan) as id_clan
    from expected e
    full outer join actual a
        on e.war_type = a.war_type and e.id_war = a.id_war and e.id_clan = a.id_clan
    where e.id_war is null or a.id_war is null
       or a.result_rows <> 1 or a.war_ids <> 1
       or e.id_war_clan is distinct from a.id_war_clan
)

select * from issues
