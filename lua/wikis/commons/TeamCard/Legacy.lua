---
-- @Liquipedia
-- page=Module:TeamCard/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')
local Tournament = Lua.import('Module:Tournament')
local Variables = Lua.import('Module:Variables')

local LegacyTeamCard = {}

---@param opts table? Optional table; supports `preprocessCard` hook.
---@return string|Widget
function LegacyTeamCard.run(opts)
    opts = opts or {}
    return ''
end

---@param rawQualifier string|table|nil
---@return {method: string, type: string, page: string?, url: string?, text: string?}?
function LegacyTeamCard.parseQualifier(rawQualifier)
    if type(rawQualifier) == 'table' then
        rawQualifier = rawQualifier[1]
    end
    if not rawQualifier or rawQualifier == '' then
        return nil
    end

    local trimmed = mw.text.trim(rawQualifier)
    local method = trimmed:lower():match('^invited?') and 'invite' or 'qual'

    local text, internalLink, externalLink = LegacyTeamCard._parseQualifierLink(rawQualifier)

    if internalLink then
        local tournament = Tournament.getTournament(internalLink)
        return {
            method = method,
            type = tournament and 'tournament' or 'internal',
            page = internalLink,
            text = text,
        }
    elseif externalLink then
        return {
            method = method,
            type = 'external',
            url = externalLink,
            text = text,
        }
    else
        return {method = method, type = 'other', text = text}
    end
end

-- Port of Module:TeamCard/Qualifier (and Module:TeamCard/Storage._parseQualifier).
---@param rawQualifier string
---@return string?, string?, string? # (linkText, internalLink, externalLink)
function LegacyTeamCard._parseQualifierLink(rawQualifier)
    local cleanQualifier = rawQualifier:gsub('%[', ''):gsub('%]', '')
    if cleanQualifier:find('|') then
        local parts = mw.text.split(cleanQualifier, '|', true)
        local link, displayName = parts[1], parts[2]
        if link:sub(1, 1) == '/' then
            link = mw.title.getCurrentTitle().fullText .. link
        end
        link = link:gsub(' ', '_')
        return displayName, link, nil
    elseif rawQualifier:sub(1, 1) == '[' then
        local parts = mw.text.split(cleanQualifier, ' ', true)
        local link = parts[1]
        table.remove(parts, 1)
        return table.concat(parts, ' '), nil, link
    else
        return rawQualifier, nil, nil
    end
end

---@param tcArgs table
---@param prefix string
---@param sourceGroup nil|'s'|'f'  -- nil for main p*, 's' for substitute source, 'f' for former
---@return table
function LegacyTeamCard.mapPlayer(tcArgs, prefix, sourceGroup)
    local wins = tonumber(tcArgs[prefix .. 'wins'])
    local winsc = tonumber(tcArgs[prefix .. 'winsc'])
    local trophies
    if wins or winsc then
        trophies = (wins or 0) + (winsc or 0)
    end

    local played = Logic.readBoolOrNil(tcArgs[prefix .. 'played']
        or tcArgs[prefix .. 'result'])
    if Logic.readBool(tcArgs[prefix .. 'dnp']) then
        played = false
    end

    local status
    if Logic.readBool(tcArgs[prefix .. 'leave']) then
        status = 'former'
    elseif Logic.readBool(tcArgs[prefix .. 'sub']) then
        status = 'sub'
    elseif sourceGroup == 's' then
        status = 'sub'
    elseif sourceGroup == 'f' then
        status = 'former'
    end

    -- Default-DNP rules (only when no explicit played/result and no explicit dnp).
    local explicitPlayResult = Logic.readBoolOrNil(tcArgs[prefix .. 'played']
        or tcArgs[prefix .. 'result'])
    if explicitPlayResult == nil and not Logic.readBool(tcArgs[prefix .. 'dnp']) then
        if sourceGroup == 's' and Logic.readBool(tcArgs.subdnpdefault) then
            played = false
        elseif sourceGroup == 'f' and Logic.readBool(tcArgs.formerdnpdefault) then
            played = false
        elseif sourceGroup ~= nil and Logic.readBool(tcArgs.noVarDefault) then
            played = false
        end
    end

    return {
        [1] = tcArgs[prefix],
        link = tcArgs[prefix .. 'link'],
        flag = tcArgs[prefix .. 'flag_o'] or tcArgs[prefix .. 'flag'],
        team = tcArgs[prefix .. 'team'],
        id = tcArgs[prefix .. 'id'],
        faction = tcArgs[prefix .. 'faction'] or tcArgs[prefix .. 'race'],
        role = tcArgs[prefix .. 'pos'],
        trophies = trophies,
        joindate = tcArgs[prefix .. 'joindate'],
        leavedate = tcArgs[prefix .. 'leavedate'],
        played = played,
        status = status,
    }
end

---@param tcArgs table
---@param prefix string
---@param sourceGroup nil|'sc'|'fc'  -- nil for main c*, 'sc' for sub-coach source, 'fc' for former-coach source
---@return table
function LegacyTeamCard.mapCoach(tcArgs, prefix, sourceGroup)
    local wins = tonumber(tcArgs[prefix .. 'wins'])
    local winsc = tonumber(tcArgs[prefix .. 'winsc'])
    local trophies
    if wins or winsc then
        trophies = (wins or 0) + (winsc or 0)
    end

    local role = tcArgs[prefix .. 'pos'] or 'coach'

    local status
    if Logic.readBool(tcArgs[prefix .. 'leave']) then
        status = 'former'
    elseif Logic.readBool(tcArgs[prefix .. 'sub']) then
        status = 'sub'
    elseif sourceGroup == 'sc' then
        status = 'sub'
    elseif sourceGroup == 'fc' then
        status = 'former'
    end

    return {
        [1] = tcArgs[prefix],
        link = tcArgs[prefix .. 'link'],
        flag = tcArgs[prefix .. 'flag_o'] or tcArgs[prefix .. 'flag'],
        team = tcArgs[prefix .. 'team'],
        role = role,
        type = 'staff',
        trophies = trophies,
        status = status,
    }
end

local MAX_PLAYER_INDEX = 25
local MAX_COACH_INDEX = 25

local TN_TYPE_DEFAULTS = {t2 = 'sub', t3 = 'former'}

---@param tcArgs table
---@param prefix string
---@param maxIndex integer
---@return integer[]
local function indicesPresent(tcArgs, prefix, maxIndex)
    return Array.filter(Array.range(1, maxIndex), function(i)
        return Logic.isNotEmpty(tcArgs[prefix .. i])
    end)
end

---@param value string?
---@return string
local function normalizeKey(value)
    if not value or value == '' then return '' end
    return value:gsub(' ', '_'):lower()
end

---@param tcArgs table
---@return table[]
function LegacyTeamCard.mapPlayers(tcArgs)
    local players = {}
    local indexByKey = {}

    local function add(person, allowOverwrite)
        local key = normalizeKey(person.link or person[1])
        if key ~= '' and indexByKey[key] then
            if allowOverwrite then
                players[indexByKey[key]] = person
            end
            return
        end
        table.insert(players, person)
        if key ~= '' then
            indexByKey[key] = #players
        end
    end

    Array.forEach(indicesPresent(tcArgs, 'p', MAX_PLAYER_INDEX), function(i)
        add(LegacyTeamCard.mapPlayer(tcArgs, 'p' .. i, nil), false)
    end)
    Array.forEach(indicesPresent(tcArgs, 's', MAX_PLAYER_INDEX), function(i)
        add(LegacyTeamCard.mapPlayer(tcArgs, 's' .. i, 's'), false)
    end)
    Array.forEach(indicesPresent(tcArgs, 'f', MAX_PLAYER_INDEX), function(i)
        add(LegacyTeamCard.mapPlayer(tcArgs, 'f' .. i, 'f'), false)
    end)

    Array.forEach({'t2', 't3'}, function(tab)
        local tabType = (tcArgs[tab .. 'type'] or TN_TYPE_DEFAULTS[tab]):lower()
        local sourceGroup
        if tabType == 'sub' then sourceGroup = 's'
        elseif tabType == 'former' then sourceGroup = 'f'
        else sourceGroup = nil end

        Array.forEach(indicesPresent(tcArgs, tab .. 'p', MAX_PLAYER_INDEX), function(i)
            local person = LegacyTeamCard.mapPlayer(tcArgs, tab .. 'p' .. i, sourceGroup)
            if tabType == 'staff' then
                person.type = 'staff'
            end
            add(person, true)
        end)
    end)

    return players
end

---@param tcArgs table
---@return table[]
function LegacyTeamCard.mapCoaches(tcArgs)
    local coaches = {}

    Array.forEach(indicesPresent(tcArgs, 'c', MAX_COACH_INDEX), function(i)
        table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'c' .. i, nil))
    end)
    Array.forEach(indicesPresent(tcArgs, 'sc', MAX_COACH_INDEX), function(i)
        table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'sc' .. i, 'sc'))
    end)
    Array.forEach(indicesPresent(tcArgs, 'fc', MAX_COACH_INDEX), function(i)
        table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'fc' .. i, 'fc'))
    end)

    Array.forEach({'t2', 't3'}, function(tab)
        local tabType = (tcArgs[tab .. 'type'] or TN_TYPE_DEFAULTS[tab]):lower()
        local sourceGroup
        if tabType == 'sub' then sourceGroup = 'sc'
        elseif tabType == 'former' then sourceGroup = 'fc'
        else sourceGroup = nil end

        Array.forEach(indicesPresent(tcArgs, tab .. 'c', MAX_COACH_INDEX), function(i)
            table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, tab .. 'c' .. i, sourceGroup))
        end)
    end)

    return coaches
end

return LegacyTeamCard
