---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Auto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Condition = require('Module:Condition')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')

local SquadUtils = require('Module:Squad/Utils')
local SquadCustom = require('Module:Squad/Custom')

local BooleanOperator = Condition.BooleanOperator
local Comparator = Condition.Comparator

---@class SquadAuto
---@field args table
---@field config SquadAutoConfig
---@field manualPlayers table?
---@field manualTimeline table?
---@field playersTeamHistory table<string, TeamHistoryEntry[]>
local SquadAuto = Class.new(nil, function (self, frame)
    self.args = Arguments.getArgs(frame)
end)

---@class SquadAutoTeam
---@field team string
---@field role string?
---@field position string?
---@field date string?

---TODO: Unify with SquadPerson
---@class SquadAutoPerson
---@field id string
---@field flag string?
---@field idleavedate string?
---@field page string
---@field name string?
---@field localizedname string?
---@field thisTeam SquadAutoTeam
---@field oldTeam SquadAutoTeam?
---@field newTeam SquadAutoTeam?
---@field joindate string
---@field joindatedisplay string?
---@field joindateRef table<string, string>?
---@field leavedate string?
---@field leavedatedisplay string
---@field leavedateRef table<string, string>?
---@field faction string?
---@field captain boolean?

---@class SquadAutoConfig
---@field team string
---@field status SquadStatus
---@field type SquadType
---@field title string?
---@field teams string[]?
---@field roles {excluded: string[], included: string[]}

---@enum TransferType
SquadAuto.TransferType = {
	LEAVE = 'LEAVE',
	JOIN = 'JOIN',
	CHANGE = 'CHANGE',
}

---@class (exact) TeamHistoryEntry
---@field pagename string
---@field displayname string
---@field flag string
---@field date string
---@field dateDisplay string
---@field type TransferType
---@field references table<string, string>
---@field wholeTeam boolean
---@field position string
---@field fromTeam string?
---@field fromRole string?
---@field toTeam string?
---@field toRole string?
---@field faction string?

local DEFAULT_INCLUDED_ROLES = {
    [SquadUtils.SquadType.PLAYER] = {
        [SquadUtils.SquadStatus.ACTIVE] = {
            '',
            'Loan',
            'Substitute',
            'Trial',
            'Stand-in',
            'Uncontracted'
        },
        [SquadUtils.SquadStatus.INACTIVE] = {
            'Inactive'
        }
    },
    [SquadUtils.SquadType.STAFF] = {},
}

local DEFAULT_EXCLUDED_ROLES = {
    [SquadUtils.SquadType.PLAYER] = {},
    [SquadUtils.SquadType.STAFF] = {
        '',
        'Loan',
        'Substitute',
        'Trial',
        'Stand-in',
        'Uncontracted',
        'Inactive'
    },
}

---Entrypoint for SquadAuto tables
---@param frame table
function SquadAuto.run(frame)
    local autosquad = SquadAuto(frame)
    autosquad:parseConfig()
    autosquad:queryTransfers()

    local entries = autosquad:selectEntries()
    Array.forEach(entries, SquadAuto.enrichEntry)

    return autosquad:display(entries)
end

---Parses the args into a SquadAutoConfig
function SquadAuto:parseConfig()
    local args = self.args
    local type = SquadUtils.TypeToSquadType[(args.type or ''):lower()]
    local status = SquadUtils.StatusToSquadStatus[(args.status or ''):lower()]
    self.config = {
        team = args.team or mw.title.getCurrentTitle().text,
        type = type,
        status = status,
        title = args.title,
        roles = {
            included = Logic.nilIfEmpty(Array.parseCommaSeparatedString(args.roles))
                or DEFAULT_INCLUDED_ROLES[type][status],
            excluded = Logic.nilIfEmpty(Array.parseCommaSeparatedString(args.not_roles))
                or DEFAULT_EXCLUDED_ROLES[type],
        }
    }

    self.manualPlayers = self:readManualPlayers()

    -- Override default 'Former Squad' title
    if status == SquadUtils.SquadStatus.FORMER
            and type == SquadUtils.SquadType.PLAYER
            and not self.config.title then
        self.config.title = 'Former Players'
    end

    local historicalTemplates = mw.ext.TeamTemplate.raw_historical(self.config.team)
    if not historicalTemplates then
        error("Missing team template: " .. self.config.team)
    end
    self.config.teams = Array.append(Array.extractValues(historicalTemplates), self.config.team)

    if self.config.status == SquadUtils.SquadStatus.FORMER_INACTIVE then
        error("SquadStatus 'FORMER_INACTIVE' is not supported by SquadAuto.")
    end

    if self.config.status == SquadUtils.SquadStatus.INACTIVE then
        table.insert(self.config.roles.included, 'Inactive')
    else
        table.insert(self.config.roles.excluded, 'Inactive')
    end
end

---@param entries SquadAutoPerson[]
---@return Widget|Html|string?
function SquadAuto:display(entries)
    if Logic.isEmpty(entries) then
        return
    end

    if self.config.status == SquadUtils.SquadStatus.FORMER then
        return self:displayTabs(entries)
    end

    entries = SquadAuto._sortEntries(entries)

    return SquadCustom.runAuto(entries, self.config.status, self.config.type, self.config.title)
end

---@param entries SquadAutoPerson[]
---@return Html|string?
function SquadAuto:displayTabs(entries)
    local _, groupedEntries = Array.groupBy(
        entries,
        ---@param entry SquadAutoPerson
        function (entry)
            return entry.leavedate:match('(%d%d%d%d)')
        end
    )

    ---@type table<string, any>
	local tabs = {
		This = Table.size(groupedEntries),
        removeEmptyTabs = true
	}

    local idx = 1
	for year, group in Table.iter.spairs(groupedEntries) do
		tabs['name' .. idx] = year
        tabs['content' .. idx] = tostring(SquadCustom.runAuto(
            SquadAuto._sortEntries(group),
            self.config.status,
            self.config.type,
            self.config.title
        ))
        idx = idx + 1
	end

    return Tabs.dynamic(tabs)
end

---@param entry SquadAutoPerson
function SquadAuto.enrichEntry(entry)
    local personInfo = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. string.gsub(entry.page, ' ', '_') .. ']]',
		limit = 1,
		query = 'pagename, nationality, id, name, localizedname, extradata'
	})[1]

	if personInfo then
        entry.id = personInfo.id
        entry.flag = personInfo.nationality
        entry.name = personInfo.name
        entry.localizedname = personInfo.localizedname
    end
    --TODO: Captain from pagevars?
end

---@return SquadAutoPerson[]
function SquadAuto:readManualPlayers()
    ---@type SquadAutoPerson[]
    local players = {}

    -- TODO: Handle manual 'enrichments' for adding names
    -- TODO: Readd limitations to specific roles?
    Array.forEach(self.args, function (entry)
        local player = Json.parseIfString(entry)
        if Logic.isNotEmpty(player) then
            table.insert(players, {
                page = player.link or player.id or player.name,
                id = player.id,
                captain = Logic.readBoolOrNil(player.captain),
                name = player.name,
                localizedname = player.localizedname,
                thisTeam = {
                    team = self.config.team,
                    role = player.role,
                    position = player.position
                },
                newTeam = {
                    team = player.newteam,
                    role = player.newteamrole,
                    player.newteamdate
                },
                flag = player.flag,
                oldTeam = {
                    team = player.oldteam
                },
                joindate = (player.joindate or ''):gsub('%?%?','01'),
                joindatedisplay = player.joindate,
                joindateRef = {},
                leavedate = (player.leavedate or ''):gsub('%?%?','01'),
                leavedatedisplay = player.leavedate,
                leavedateRef = {},
                faction = player.faction or player.race,
                race = player.faction or player.race,
            })
        end
    end)

    return players
end

function SquadAuto:queryTransfers()
    ---Checks whether a given team is the currently queried team
    ---@param team string?
    ---@return boolean
    local function isCurrentTeam(team)
        if not team then
            return false
        end
        return Array.find(self.config.teams, function(t) return t == team end) ~= nil
    end

    ---@param side 'from' | 'to'
    ---@param transfer transfer
    ---@return string | nil, boolean
    local function parseRelevantTeam(side, transfer)
        local mainTeam = transfer[side .. 'teamtemplate']
        if mainTeam and isCurrentTeam(mainTeam) then
            return mainTeam, true
        end

        local secondaryTeam = transfer.extradata[side .. 'teamsectemplate']
        if secondaryTeam and isCurrentTeam(secondaryTeam) then
            return secondaryTeam, false
        end

        return nil, false
    end

    ---Maps a transfer to a transfertype, with regards to the current team.
    ---@param relevantFromTeam string?
    ---@param relevantToTeam string?
    ---@return TransferType
    local function getTransferType(relevantFromTeam, relevantToTeam)
        if relevantFromTeam then
            if relevantToTeam then
                return SquadAuto.TransferType.CHANGE
            end
            return SquadAuto.TransferType.LEAVE
        end
        return SquadAuto.TransferType.JOIN
    end

    ---Parses the relevant role for the current team from a transfer
    ---@param side 'from' | 'to'
    ---@param transfer transfer
    ---@param team string?
    ---@param isMain boolean
    ---@return string?
    local function parseRelevantRole(side, transfer, team, isMain)
        if not team then
            return nil
        end

        if isMain then
            return side == 'from' and transfer.role1 or transfer.role2
        else
            return side == 'from' and transfer.extradata.role1sec or transfer.extradata.role2sec
        end
    end

    --TODO: Cache transfers/teamhistory in pagevars
    ---@type table<string, TeamHistoryEntry>
    self.playersTeamHistory = {}

    Lpdb.executeMassQuery(
        'transfer',
        {
            conditions = self:buildConditions(),
            order = 'date asc, objectname desc',
            limit = 5000
        },
        function(record)
            self.playersTeamHistory[record.player] = self.playersTeamHistory[record.player] or {}
            record.extradata = record.extradata or {}


            local relevantFromTeam, isFromMain = parseRelevantTeam('from', record)
            local relevantToTeam, isToMain = parseRelevantTeam('to', record)
            local transferType = getTransferType(relevantFromTeam, relevantToTeam)

            -- For leave transfers: Pass on new team for display as next team
            if transferType == SquadAuto.TransferType.LEAVE and Logic.isEmpty(relevantToTeam) then
                relevantToTeam = isFromMain
                    and Logic.nilIfEmpty(record.toteamtemplate)
                    or record.extradata.toteamsectemplate
            end

            ---@type TeamHistoryEntry
            local entry = {
                type = transferType,

                -- Person related information
                pagename = record.player,
                displayname = record.extradata.displayname,
                flag = record.nationality,

                -- Date and references
                date = record.date,
                dateDisplay = record.extradata.displaydate,
                references = record.reference,

                -- Roles
                fromRole = parseRelevantRole('from', record, relevantFromTeam, isFromMain),
                toRole = parseRelevantRole('to', record, relevantToTeam, isToMain),

                fromTeam = relevantFromTeam,
                toTeam = relevantToTeam,

                -- Other
                wholeTeam = Logic.readBool(record.wholeteam),
                position = record.extradata.position,
                faction = record.extradata.faction
            }

            -- Skip this transfer if there is no relevant change, i.e. the role in this team didn't change
            -- E.g. this is grabbed by secondary team, but only main team changed
            if relevantFromTeam == relevantToTeam
                    and entry.fromRole == entry.toRole then
                return
            end

            table.insert(self.playersTeamHistory[record.player], entry)
        end
    )
end

---Builds the conditions to fetch all transfers related
---to the given team, respecting historical templates.
---@return string
function SquadAuto:buildConditions()
    local historicalTemplates = mw.ext.TeamTemplate.raw_historical(self.config.team)

    if not historicalTemplates then
        error("Missing team template: " .. self.config.team)
    end

    local conditions = Condition.Tree(BooleanOperator.any)
    Array.forEach(Array.extendWith(Array.extractValues(historicalTemplates), self.config.team), function (templatename)
        conditions:add{
            Condition.Node(Condition.ColumnName('fromteamtemplate'), Comparator.eq, templatename),
            Condition.Node(Condition.ColumnName('extradata_fromteamsectemplate'), Comparator.eq, templatename),
            Condition.Node(Condition.ColumnName('toteamtemplate'), Comparator.eq, templatename),
            Condition.Node(Condition.ColumnName('extradata_toteamsectemplate'), Comparator.eq, templatename)
        }
    end)

    return conditions:toString()
end

---@return SquadAutoPerson[]
function SquadAuto:selectEntries()
    return Array.filter(
        Array.extend(
            Array.flatMap(
                Array.extractValues(self.playersTeamHistory),
                FnUtil.curry(self._selectHistoryEntries, self)
            ),
            self.manualPlayers
        ),
        ---@param entry SquadAutoPerson
        function(entry)
            local result = (
                Logic.isEmpty(self.config.roles.included)
                or Array.any(
                    self.config.roles.included,
                    FnUtil.curry(Operator.eq, entry.thisTeam.role)
                )
            ) and (
                Logic.isEmpty(self.config.roles.excluded)
                or Array.all(
                    self.config.roles.excluded,
                    FnUtil.curry(Operator.neq, entry.thisTeam.role)
                )
            )

            return result
        end
    )
end

---Returns a function that maps a set of transfers to a list of SquadAutoPersons.
---Behavior depends on the current config:
---If the status is (in)active, then at most one entry will be returned
---If the status is former(_inactive), there might be multiple entries returned
---If the type does not match, no entries are returned
---@param entries TeamHistoryEntry[]
---@return SquadAutoPerson[]
function SquadAuto:_selectHistoryEntries(entries)
    -- Select entries to match status
    if self.config.status == SquadUtils.SquadStatus.ACTIVE then
        -- Only most recent transfer is relevant
        local last = entries[#entries]
        if last.type == SquadAuto.TransferType.CHANGE
                or last.type == SquadAuto.TransferType.JOIN then
            -- When the last transfer is a leave transfer, the person wouldn't be active
            return {self:_mapToSquadAutoPerson(last)}
        end
    end

    if self.config.status == SquadUtils.SquadStatus.INACTIVE then
        local last, secondToLast = entries[#entries], entries[#entries - 1]
        if secondToLast and last.type == SquadAuto.TransferType.CHANGE then
            return {self:_mapToSquadAutoPerson(secondToLast, last)}
        end
    end

    if self.config.status == SquadUtils.SquadStatus.FORMER then
        local history = {}

        local currentEntry = nil

        Array.forEach(entries, function (entry)
            if not currentEntry then
                if entry.type == SquadAuto.TransferType.JOIN then
                    currentEntry = entry
                else
                    mw.log("Invalid transfer history for player " .. entry.pagename)
                    mw.logObject(entry, "Invalid entry: Missing previous JOIN. Skipping")
                    mw.ext.TeamLiquidIntegration.add_category('SquadAuto with invalid player history')
                end
                return
            end

            table.insert(history, self:_mapToSquadAutoPerson(currentEntry, entry))
            if entry.type == "CHANGE" then
                currentEntry = entry
            else
                currentEntry = nil
            end
        end)

        return history
    end

    return {}
end

---Maps one or a pair of TeamHistoryEntries to a single SquadAutoPerson
---@param joinEntry TeamHistoryEntry
---@param leaveEntry TeamHistoryEntry | nil
---@return SquadAutoPerson
function SquadAuto:_mapToSquadAutoPerson(joinEntry, leaveEntry)
    leaveEntry = leaveEntry or {}

    ---@type SquadAutoPerson
    local entry =  {
        page = joinEntry.pagename,
        id = joinEntry.displayname,
        flag = joinEntry.flag,
        joindate = joinEntry.date,
        joindatedisplay = joinEntry.dateDisplay,
        joindateRef = joinEntry.references,

        idleavedate = leaveEntry.displayname,
        leavedate = leaveEntry.date,
        leavedatedisplay = leaveEntry.dateDisplay or '',
        leavedateRef = leaveEntry.references,

        thisTeam = {
            team = joinEntry.toTeam,
            role = joinEntry.toRole,
            position = joinEntry.position
        },
        oldTeam = {
            team = joinEntry.fromTeam,
            role = joinEntry.fromRole,
        },
        newTeam = {
            team = leaveEntry.toTeam,
            role = leaveEntry.toRole,
        },

        -- From legacy: Prefer faction information from leaveEntry
        faction = leaveEntry.faction or joinEntry.faction,
        race = leaveEntry.faction or joinEntry.faction
    }

    -- On leave: Fetch the next team a person joined
    if Logic.isNotEmpty(leaveEntry) and Logic.isEmpty(entry.newTeam.team) then
        local newTeam, newRole = SquadAuto._fetchNextTeam(joinEntry.pagename, leaveEntry.date)
        if newTeam then
            entry.newTeam.team = newTeam
            entry.newTeam.role = newRole
        end
    end

    -- Special case: Person went inactive.
    -- Set thisTeam.role to inactive and remove newTeam.role,
    -- otherwise Squad doesn't display the entries
    if self.config.status == SquadUtils.SquadStatus.INACTIVE
            and leaveEntry.toRole == "Inactive" then
        entry.thisTeam.role = entry.newTeam.role
        entry.newTeam.role = ""
    end

    return entry
end

---Fetches the next team a person joined after a given date
---@param pagename string
---@param date string
---@return string?
---@return string?
function SquadAuto._fetchNextTeam(pagename, date)
    local conditions = Condition.Tree(BooleanOperator.all)
        :add{
            Condition.Node(Condition.ColumnName('player'), Comparator.eq, string.gsub(pagename, ' ', '_')),
            Condition.Tree(BooleanOperator.any):add{
                Condition.Node(Condition.ColumnName('date'), Comparator.gt, date),
            }
        }

    local transfer = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = conditions:toString(),
		limit = 1,
        order = 'date asc, objectname desc',
		query = 'toteamtemplate, role2'
	})[1] or {}

    -- TODO: Check if fetched transfer is in fact a join transfer (empty fromTeam)?

    return transfer.toteamtemplate, transfer.role2
end

---Sorts a list of SquadAutoPersons
-- Active entries (no leavedate) sorted by joindate,
-- Former entries sorted by leavedate
---@param entries SquadAutoPerson[]
---@return unknown[]
function SquadAuto._sortEntries(entries)
    return Array.sortBy(entries, function (element)
        return {element.leavedate or element.joindate, element.id}
    end)
end

return SquadAuto
