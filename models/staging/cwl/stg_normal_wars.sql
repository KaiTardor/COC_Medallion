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
from {{ source('cwl_bronze', 'normal_wars') }}