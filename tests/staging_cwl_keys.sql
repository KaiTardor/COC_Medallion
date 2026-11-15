select
    'grupo_duplicado' as problema,
    season as clave_1,
    group_id as clave_2
from {{ ref('stg_groups') }}
group by season, group_id
having count(*) > 1

union all

select
    'perspectiva_duplicada',
    war_id,
    clan_tag
from {{ ref('stg_normal_wars') }}
group by war_id, clan_tag
having count(*) > 1

union all

select
    'guerra_cwl_sin_grupo',
    w.season,
    w.war_tag
from {{ ref('stg_cwl_wars') }} w
left join {{ ref('stg_groups') }} g
    on w.season = g.season
    and w.group_id = g.group_id
where g.group_id is null