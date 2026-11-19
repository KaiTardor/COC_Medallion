with staged_coverage as (
    select
        season,
        id_clan,
        fetched_at_utc,
        status,
        error_reason,
        records_captured,
        oldest_log_day,
        newest_log_day,
        history_reaches_month_start
    from {{ ref('stg_normal_war_coverage') }}
    qualify row_number() over (
        partition by season, id_clan
        order by fetched_at_utc desc nulls last,
            (status = 'ok') desc nulls last,
            records_captured desc nulls last,
            history_reaches_month_start desc nulls last,
            oldest_log_day asc nulls last,
            newest_log_day desc nulls last,
            status asc nulls last,
            error_reason asc nulls last
    ) = 1
),

coverage as (
    select
        {{ coc_id('coverage', ['season', 'id_clan']) }} as id_coverage,
        season,
        id_clan,
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