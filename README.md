# COC Medallion

Proyecto dbt sobre Snowflake para analizar el rendimiento de clanes de Clash of Clans en la Liga de Guerras de Clanes (CWL) y en guerras normales.

## Flujo de datos

1. Python exporta los lotes a NDJSON. El flujo de n8n en DEV compara las capturas con Bronze, carga las novedades y dispara el job de dbt.
2. **Bronze** guarda los registros originales en `CWL_GROUPS_RAW`, `CWL_WARS_RAW`, `NORMAL_WARS_RAW` y `NORMAL_WAR_COVERAGE_RAW`.
3. **Staging** extrae y tipa los campos del JSON en vistas. 
4. **Silver** organiza las entidades, los bandos, los participantes y los ataques, y consolida las perspectivas de una misma guerra normal.
5. **Gold** prepara el rendimiento en CWL, el aprovechamiento de ataques, la dificultad por nivel de Ayuntamiento y la comparación entre CWL y guerras normales con su cobertura.

## Entornos de Snowflake

| Capa | DEV | PRO con el target `pro` |
|---|---|---|
| Bronze | `DEV_COC_BRONZE.BRONZE` | `PRO_COC_BRONZE.BRONZE` |
| Staging | `DEV_COC_SILVER.DBT_HHU` | `PRO_COC_SILVER.STAGING` |
| Silver | `DEV_COC_SILVER.DBT_HHU` | `PRO_COC_SILVER.SILVER` |
| Gold | `DEV_COC_GOLD.DBT_HHU` | `PRO_COC_GOLD.GOLD` |

## Ejecución y validación

Con el perfil del entorno y las variables anteriores configurados, ejecuta:

```bash
dbt parse
dbt build
```

`dbt build` construye los modelos y ejecuta sus tests. Los tests comprueban claves, relaciones y coherencia entre bandos, participantes, ataques y perspectivas de guerras.

## Modelos incrementales

| Capa | Modelos |
|---|---|
| Silver | `cwl_wars`, `cwl_war_clans`, `cwl_war_participants`, `attacks_defenses`, `normal_wars` |
| Gold | `fct_cwl_attacks` |

Los incrementales comparan una huella de las entradas por guerra con la guardada en destino. Si cambia, recalculan la guerra afectada y aplican inserciones, actualizaciones o borrados mediante `MERGE`. Los demás modelos de Silver y Gold se reconstruyen como tablas en cada build. Staging se materializa como vistas.

