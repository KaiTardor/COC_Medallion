with registered as (
    select
        id_group_clan,
        id_group,
        id_clan,
        clan_level as clan_level_observed
    from ({{ coc_group_clans(ref('stg_groups')) }}) as extracted_group_clans
)

select * from registered