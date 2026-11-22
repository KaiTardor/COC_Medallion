with leagues as (
    select
        id_division,
        division_id_source,
        division_name
    from {{ ref('leagues') }}
),

divisions as (
    select
        id_division,
        division_id_source as division_id,
        division_name
    from leagues
)

select * from divisions
