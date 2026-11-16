with source as (
    select record
    from {{ source('cwl_bronze', 'normal_war_coverage') }}
),

renamed as (
    select
        record:season::varchar as season,
        record:clan_tag::varchar as clan_tag,
        record:fetched_at_utc::timestamp_tz as fetched_at_utc,
        record:payload.status::varchar as status,
        record:payload.error_reason::varchar as error_reason,
        record:payload.wars::integer as records_captured,
        record:payload.oldest_log_day::date as oldest_log_day,
        record:payload.newest_log_day::date as newest_log_day,
        record:payload.history_reaches_month_start::boolean as history_reaches_month_start
    from source
)

select * from renamed
