with source as (
    select record
    from {{ source('cwl_bronze', 'groups') }}
),

renamed as (
    select
        record:season::varchar as season,
        record:group_id::varchar as group_id,
        record:division_id::varchar as division_id,
        record:division_name::varchar as division_name,
        record:source_path::varchar as source_path,
        record:payload as payload
    from source
),

keyed as (
    select
        renamed.*,
        {{ coc_id('season', ['season']) }} as id_season,
        {{ coc_id('division', ['division_id']) }} as id_division,
        {{ coc_id('group', ['id_season', 'group_id']) }} as id_group
    from renamed
)

select * from keyed