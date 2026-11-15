{% test unique_key_columns(model, column_names) %}

select
    {{ column_names | join(', ') }},
    count(*) as row_count
from {{ model }}
group by {{ column_names | join(', ') }}
having count(*) > 1

{% endtest %}
