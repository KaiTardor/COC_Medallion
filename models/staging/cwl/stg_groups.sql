select
    record:season::varchar as season,
    record:group_id::varchar as group_id,
    record:division_id::varchar as division_id,
    record:division_name::varchar as division_name,
    record:source_path::varchar as source_path,
    record:payload as payload
from {{ source('cwl_bronze', 'groups') }}