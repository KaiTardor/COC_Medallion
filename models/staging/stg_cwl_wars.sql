with source as (
    select record
    from {{ source('cwl_bronze', 'wars') }}
),

renamed as (
    select
        record:season::varchar as season,
        record:group_id::varchar as group_id,
        record:war_tag::varchar as war_tag,
        record:round_number::integer as round_number,
        record:payload.teamSize::integer as team_size,
        record:payload.state::varchar as war_state,
        record:payload.clan.tag::varchar as clan_tag,
        record:payload.opponent.tag::varchar as opponent_tag,
        record:source_path::varchar as source_path,
        record:payload as payload
    from source
),

keyed as (
    select
        renamed.*,
        {{ coc_id('season', ['season']) }} as id_season,
        {{ coc_id('group', ['id_season', 'group_id']) }} as id_group,
        {{ coc_id('cwl_war', ['war_tag']) }} as id_cwl_war
    from renamed
)

select * from keyed