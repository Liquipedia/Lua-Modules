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

return LegacyTeamCard
