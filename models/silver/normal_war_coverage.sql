with staged_coverage as (
    select
        season,
        clan_tag,
        fetched_at_utc,
        status,
        error_reason,
        records_captured,
        oldest_log_day,
        newest_log_day,
        history_reaches_month_start
    from {{ ref('stg_normal_war_coverage') }}
),

coverage as (
    select
        season,
        clan_tag,
        fetched_at_utc,
        status,
        error_reason,
        status = 'ok' as history_accessible,
        case when status = 'ok' then records_captured end as wars_recovered,
        oldest_log_day,
        newest_log_day,
        history_reaches_month_start
    from staged_coverage
)

select * from coverage
