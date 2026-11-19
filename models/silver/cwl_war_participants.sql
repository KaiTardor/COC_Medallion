with participants as (
    select
        id_participation,
        id_war_clan,
        id_player,
        town_hall_level,
        map_position,
        coalesce(array_size(attacks_payload), 0) as attacks_used,
        attacks_received,
        player_name as player_name_observed
    from ({{ coc_war_participants(ref('stg_cwl_wars')) }}) as extracted_participants
)

select * from participants