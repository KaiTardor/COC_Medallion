{% macro coc_wars_to_process(war_key, hash_columns) %}
current_wars as (
    select
        {{ war_key }},
        hash_agg({{ hash_columns | join(', ') }}) as war_source_hash
    from war_inputs
    group by {{ war_key }}
),

{% if is_incremental() %}
previous_wars as (
    select {{ war_key }}, max(war_source_hash) as war_source_hash
    from {{ this }}
    group by {{ war_key }}
),

wars_to_process as (
    select
        coalesce(c.{{ war_key }}, p.{{ war_key }}) as {{ war_key }},
        c.war_source_hash
    from current_wars c
    full outer join previous_wars p on c.{{ war_key }} = p.{{ war_key }}
    where c.war_source_hash is distinct from p.war_source_hash
),
{% else %}
wars_to_process as (
    select {{ war_key }}, war_source_hash
    from current_wars
),
{% endif %}

selected_wars as (
    select i.*
    from war_inputs i
    inner join wars_to_process w on i.{{ war_key }} = w.{{ war_key }}
)
{% endmacro %}


{% macro coc_war_rows(rows_cte, war_key, row_key) %}
select
    r.*,
    w.war_source_hash{% if is_incremental() %},
    false as coc_delete_row{% endif %}
from {{ rows_cte }} r
inner join wars_to_process w on r.{{ war_key }} = w.{{ war_key }}

{% if is_incremental() %}
-- Emit deletes even when a corrected war produces no remaining detail rows.
union all by name

select
    existing.*,
    true as coc_delete_row
from {{ this }} existing
inner join wars_to_process w on existing.{{ war_key }} = w.{{ war_key }}
left join {{ rows_cte }} r on existing.{{ row_key }} = r.{{ row_key }}
where r.{{ row_key }} is null
{% endif %}
{% endmacro %}


{% macro get_incremental_coc_war_merge_sql(arg_dict) %}
{% set columns = arg_dict['dest_columns'] | map(attribute='quoted') | list %}
{% set row_key = arg_dict['unique_key'] %}

merge into {{ arg_dict['target_relation'] }} as target_row
using {{ arg_dict['temp_relation'] }} as incoming
    on target_row.{{ row_key }} = incoming.{{ row_key }}
when matched and incoming.coc_delete_row then delete
when matched then update set
    {% for column in columns -%}
    {{ column }} = incoming.{{ column }}{{ ',' if not loop.last }}
    {% endfor %}
when not matched and not incoming.coc_delete_row then insert ({{ columns | join(', ') }})
values (
    {% for column in columns -%}
    incoming.{{ column }}{{ ',' if not loop.last }}
    {% endfor %}
)
{% endmacro %}
