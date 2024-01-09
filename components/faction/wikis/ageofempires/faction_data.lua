---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Faction/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')

local AOE2_SUFFIX = '/Age of Empires II'

local factionPropsAoE2 = {
    armenians = {
        index = 1,
        name = 'Armenians',
        faction = 'armenians',
    },
    aztecs = {
        index = 2,
        name = 'Aztecs',
        pageName = 'Aztecs' .. AOE2_SUFFIX,
        faction = 'aztecs',
    },
    berbers = {
        index = 3,
        name = 'Berbers',
        faction = 'berbers',
    },
    bengalis = {
        index = 4,
        name = 'Bengalis',
        faction = 'bengalis',
    },
    bohemians = {
        index = 4,
        name = 'Bohemians',
        faction = 'bohemians',
    },
    britons = {
        index = 5,
        name = 'Britons',
        faction = 'britons',
    },
    bulgarians = {
        index = 6,
        name = 'Bulgarians',
        faction = 'bulgarians',
    },
    burgundians = {
        index = 7,
        name = 'Burgundians',
        faction = 'burgundians',
    },
    burmese = {
        index = 8,
        name = 'Burmese',
        faction = 'burmese',
    },
    byzantines = {
        index = 9,
        name = 'Byzantines',
        faction = 'byzantines',
    },
    celts = {
        index = 10,
        name = 'Celts',
        pageName = 'Celts' .. AOE2_SUFFIX,
        faction = 'celts',
    },
    chinese = {
        index = 11,
        name = 'Chinese',
        pageName = 'Chinese' .. AOE2_SUFFIX,
        faction = 'chinese',
    },
    cumans = {
        index = 12,
        name = 'Cumans',
        faction = 'cumans',
    },
    dravidians = {
        index = 13,
        name = 'Dravidians',
        faction = 'dravidians',
    },
    ethiopians = {
        index = 14,
        name = 'Ethiopians',
        faction = 'ethiopians',
    },
    franks = {
        index = 15,
        name = 'Franks',
        faction = 'franks',
    },
    georgians = {
        index = 16,
        name = 'Georgians',
        faction = 'georgians',
    },
    goths = {
        index = 17,
        name = 'Goths',
        faction = 'goths',
    },
    gurjaras = {
        index = 18,
        name = 'Gurjaras',
        faction = 'gurjaras',
    },
    hindustanis = {
        index = 19,
        name = 'Hindustanis',
        faction = 'hindustanis',
    },
    huns = {
        index = 20,
        name = 'Huns',
        faction = 'huns',
    },
    incas = {
        index = 21,
        name = 'Incas',
        pageName = 'Incas' .. AOE2_SUFFIX,
        faction = 'incas',
    },
    indians = {
        index = 22,
        name = 'Indians',
        pageName = 'Indians' .. AOE2_SUFFIX .. '/The_Forgotten',
        faction = 'indians',
    },
    italians = {
        index = 23,
        name = 'Italians',
        faction = 'italians',
    },
    japanese = {
        index = 24,
        name = 'Japanese',
        pageName = 'Japanese' .. AOE2_SUFFIX,
        faction = 'japanese',
    },
    khmer = {
        index = 25,
        name = 'Khmer',
        faction = 'khmer',
    },
    koreans = {
        index = 26,
        name = 'Koreans',
        faction = 'koreans',
    },
    lithuanians = {
        index = 27,
        name = 'Lithuanians',
        faction = 'lithuanians',
    },
    magyars = {
        index = 28,
        name = 'Magyars',
        faction = 'magyars',
    },
    malay = {
        index = 29,
        name = 'Malay',
        faction = 'malay',
    },
    malians = {
        index = 30,
        name = 'Malians',
        pageName = 'Malians' .. AOE2_SUFFIX,
        faction = 'malians',
    },
    mayans = {
        index = 31,
        name = 'Mayans',
        faction = 'mayans',
    },
    mongols = {
        index = 32,
        name = 'Mongols',
        pageName = 'Mongols' .. AOE2_SUFFIX,
        faction = 'mongols',
    },
    persians = {
        index = 33,
        name = 'Persians',
        pageName = 'Persians' .. AOE2_SUFFIX,
        faction = 'persians',
    },
    poles = {
        index = 34,
        name = 'Poles',
        faction = 'poles',
    },
    portuguese = {
        index = 35,
        name = 'Portuguese',
        pageName = 'Portuguese' .. AOE2_SUFFIX,
        faction = 'portuguese',
    },
    romans = {
        index = 36,
        name = 'Romans',
        pageName = 'Romans' .. AOE2_SUFFIX,
        faction = 'romans',
    },
    saracens = {
        index = 37,
        name = 'Saracens',
        faction = 'saracens',
    },
    sicilians = {
        index = 38,
        name = 'Sicilians',
        faction = 'sicilians',
    },
    slavs = {
        index = 39,
        name = 'Slavs',
        faction = 'slavs',
    },
    spanish = {
        index = 40,
        name = 'Spanish',
        pageName = 'Spanish' .. AOE2_SUFFIX,
        faction = 'spanish',
    },
    tatars = {
        index = 41,
        name = 'Tatars',
        faction = 'tatars',
    },
    teutons = {
        index = 42,
        name = 'Teutons',
        faction = 'teutons',
    },
    turks = {
        index = 43,
        name = 'Turks',
        faction = 'turks',
    },
    vietnamese = {
        index = 44,
        name = 'Vietnamese',
        faction = 'vietnamese',
    },
    vikings = {
        index = 45,
        name = 'Vikings',
        pageName = 'Vikings' .. AOE2_SUFFIX,
        faction = 'vikings',
    },

    unknown = {
        index = 46,
        name = 'Unknown',
        faction = 'unknown',
    },
}

return {
    factionProps = {
        aoe2 = factionPropsAoE2,
    },
    defaultFaction = 'unknown',
    factions = {
        aoe2 = Array.extractKeys(factionPropsAoE2)
    },
    aliases = {
        aoe2 = {

        },
    },
}
