-- Macro que genera el id mediante SHA-256 a partir de la clave de cada entidad

{% macro coc_id(entity, columns) -%}
    case
        when {{ columns | join(' is null or ') }} is null then null
        else sha2(
            to_json(array_construct(
                '{{ entity }}'
                {%- for column in columns %},
                cast({{ column }} as varchar)
                {%- endfor %}
            )),
            256
        )
    end
{%- endmacro %}