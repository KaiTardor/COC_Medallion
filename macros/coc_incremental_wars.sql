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
        c.{{ war_key }},
        c.war_source_hash
    from current_wars c
    left join previous_wars p on c.{{ war_key }} = p.{{ war_key }}
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


{% macro coc_war_rows(rows_cte, war_key) %}
select
    r.*,
    w.war_source_hash
from {{ rows_cte }} r
inner join wars_to_process w on r.{{ war_key }} = w.{{ war_key }}
{% endmacro %}
