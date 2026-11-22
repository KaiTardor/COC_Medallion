with group_details as (
    select
        id_group,
        group_id_source as group_id,
        id_division
    from {{ ref('cwl_groups') }}
)

select * from group_details