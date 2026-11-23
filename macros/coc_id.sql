-- ID numérico de la entidad a partir de los 64 bits inferiores de MD5.

{% macro coc_id(entity, columns) -%}
    case
        when {{ columns | join(' is null or ') }} is null then null
        else md5_number_lower64(
            to_json(array_construct(
                '{{ entity }}'
                {%- for column in columns %},
                cast({{ column }} as varchar)
                {%- endfor %}
            ))
        )::number(20, 0)
    end
{%- endmacro %}