with wars as (
    select
        id_cwl_war,
        id_group,
        war_tag,
        round_number,
        team_size,
        1 as attacks_per_member
    from {{ ref('stg_cwl_wars') }}
    where war_state = 'warEnded'
)

select * from wars