with group_details as (
    select
        g.id_group,
        g.group_id_source as group_id,
        s.season,
        g.id_division,
        l.division_id_source as division_id,
        l.division_name
    from {{ ref('cwl_groups') }} g
    inner join {{ ref('cwl_seasons') }} s
        on g.id_season = s.id_season
    left join {{ ref('leagues') }} l
        on g.id_division = l.id_division
)

select * from group_details