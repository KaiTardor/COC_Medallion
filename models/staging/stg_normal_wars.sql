with source as (
    select record
    from {{ source('cwl_bronze', 'normal_wars') }}
),

renamed as (
    select
        record:season::varchar as season,
        record:war_id::varchar as war_id,
        record:clan_tag::varchar as clan_tag,
        record:opponent_tag::varchar as opponent_tag,
        record:end_time_utc::timestamp_tz as end_time_utc,
        record:payload.result::varchar as result,
        record:payload.teamSize::integer as team_size,
        record:payload.attacksPerMember::integer as attacks_per_member,
        record:payload.clan.attacks::integer as attacks_used,
        record:payload.clan.stars::integer as stars,
        record:payload.clan.destructionPercentage::float as destruction_pct,
        record:source_path::varchar as source_path,
        record:payload as payload
    from source
),

keyed as (
    select
        renamed.*,
        {{ coc_id('clan', ['clan_tag']) }} as id_clan,
        {{ coc_id('clan', ['opponent_tag']) }} as id_opponent_clan,
        to_char(convert_timezone('UTC', end_time_utc), 'YYYY-MM-DD"T"HH24:MI:SS.FF9"Z"') as end_time_key,
        least(clan_tag, opponent_tag) as clan_a_tag,
        greatest(clan_tag, opponent_tag) as clan_b_tag,
        {{ coc_id('normal_war', ['end_time_key', 'clan_a_tag', 'clan_b_tag']) }} as id_normal_war
    from renamed
)

select * from keyed