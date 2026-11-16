select
    id_clan,
    clan_tag,
    clan_name,
    name_observed_season,
    clan_level,
    level_observed_season
from {{ ref('clans') }}