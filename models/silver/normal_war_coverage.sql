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
),

ranked_attempts as (
    select
        staged_coverage.*,
        row_number() over (
            partition by season, id_clan
            order by fetched_at_utc desc nulls last,
                (status = 'ok') desc nulls last,
                records_captured desc nulls last,
                history_reaches_month_start desc nulls last,
                oldest_log_day asc nulls last, newest_log_day desc nulls last,
                status asc nulls last, error_reason asc nulls last
        ) as attempt_rank
    from staged_coverage
),

latest_attempt as (
    select *
    from ranked_attempts
    where attempt_rank = 1
),

successful_attempts as (
    select
        ranked_attempts.*,
        max(case when history_reaches_month_start
            and convert_timezone('UTC', fetched_at_utc)::date >=
                dateadd(month, 1, to_date(season || '-01', 'YYYY-MM-DD'))
            then 1 else 0 end
        ) over (partition by season, id_clan) as has_complete_capture
    from ranked_attempts
    where status = 'ok'
),

latest_success as (
    select *
    from successful_attempts
    qualify row_number() over (partition by season, id_clan order by attempt_rank) = 1
),

coverage as (
    select
        {{ coc_id('coverage', ['a.season', 'a.id_clan']) }} as id_coverage,
        a.season,
        a.id_clan,
        a.fetched_at_utc,
        a.status,
        a.error_reason,
        a.status = 'ok' as history_accessible,
        s.fetched_at_utc as last_success_at_utc,
        s.records_captured as wars_recovered,
        s.oldest_log_day,
        s.newest_log_day,
        s.history_reaches_month_start,
        case
            when s.has_complete_capture = 1 then 'complete'
            when s.status = 'ok' then 'partial'
            else 'unknown'
        end as coverage_status
    from latest_attempt a
    left join latest_success s on a.season = s.season and a.id_clan = s.id_clan
)

select * from coverage