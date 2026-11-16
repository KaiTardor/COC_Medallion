{% macro coc_group_clans(groups_relation) %}
select
    gc.season,
    gc.id_group,
    gc.clan_tag,
    gc.clan_name,
    gc.clan_level,
    gc.roster_payload,
    gc.id_clan,
    {{ coc_id('group_clan', ['gc.id_group', 'gc.id_clan']) }} as id_group_clan
from (
    select
        g.season,
        g.id_group,
        c.value:tag::varchar as clan_tag,
        c.value:name::varchar as clan_name,
        c.value:clanLevel::integer as clan_level,
        c.value:members as roster_payload,
        {{ coc_id('clan', ['c.value:tag::varchar']) }} as id_clan
    from {{ groups_relation }} g,
        lateral flatten(input => g.payload:clans) c
) as gc
{% endmacro %}


{% macro coc_roster(groups_relation) %}
select
    gc.season,
    gc.id_group_clan,
    m.value:tag::varchar as player_tag,
    m.value:name::varchar as player_name,
    coalesce(m.value:townHallLevel, m.value:townhallLevel)::integer as town_hall_level,
    {{ coc_id('player', ['m.value:tag::varchar']) }} as id_player
from ({{ coc_group_clans(groups_relation) }}) as gc,
    lateral flatten(input => gc.roster_payload) m
{% endmacro %}

{% macro coc_war_participants(wars_relation) %}
select
    p.*,
    {{ coc_id('participation', ['p.id_cwl_war', 'p.id_player']) }} as id_participation
from (
    select
        w.season,
        w.id_cwl_war,
        w.round_number,
        s.value:tag::varchar as clan_tag,
        m.value:tag::varchar as player_tag,
        m.value:name::varchar as player_name,
        coalesce(
            m.value:townhallLevel,
            m.value:townHallLevel
        )::integer as town_hall_level,
        m.value:mapPosition::integer as map_position,
        m.value:attacks as attacks_payload,
        {{ coc_id('clan', ['s.value:tag::varchar']) }} as id_clan,
        {{ coc_id('player', ['m.value:tag::varchar']) }} as id_player
    from {{ wars_relation }} w,
        lateral flatten(
            input => array_construct(w.payload:clan, w.payload:opponent)
        ) s,
        lateral flatten(input => s.value:members) m
    where w.war_state = 'warEnded'
) as p
{% endmacro %}