with members as (
    select id_group_clan, id_player, town_hall_level, player_name
    from ({{ coc_roster(ref('stg_groups')) }}) as extracted_roster
),

roster as (
    select
        {{ coc_id('roster_entry', ['id_group_clan', 'id_player']) }} as id_roster_entry,
        id_group_clan,
        id_player,
        town_hall_level as town_hall_level_observed,
        player_name as player_name_observed
    from members
)

select * from roster