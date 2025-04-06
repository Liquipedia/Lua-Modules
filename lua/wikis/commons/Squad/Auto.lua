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
local Table = require('Module:Table')
local Operator = require('Module:Operator')

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
---@field leavedatedisplay string?
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
        '',
        'Loan',
        'Substitute',
        'Trial',
        'Stand-in',
        'Uncontracted'
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
        'Uncontracted'
    },
}

---Entrypoint for the automated timelin
---TODO: Implement in submodule
function SquadAuto.timeline(frame)
    -- return SquadAuto(frame):timeline()
end

---Entrypoint for SquadAuto tables
---@param frame table
function SquadAuto.run(frame)
    local autosquad = SquadAuto(frame)
    autosquad:parseConfig()
    autosquad:queryTransfers()

    return autosquad:display()
end

function SquadAuto:display()
    local entries = self:selectEntries()
    mw.logObject(entries)
    return SquadCustom.runAuto(entries, self.config.status, self.config.type, self.config.title)
end

---Parses the args into a SquadAutoConfig
function SquadAuto:parseConfig()
    local args = self.args
    local type = SquadUtils.TypeToSquadType[(args.type or ''):lower()]
    self.config = {
        team = args.team or mw.title.getCurrentTitle().text,
        status = SquadUtils.StatusToSquadStatus[(args.status or ''):lower()],
        type = type,
        title = args.title, -- TODO: Switch to Former players instead of squad?
        roles = {
            included = Logic.nilIfEmpty(Array.parseCommaSeparatedString(args.roles)) or DEFAULT_INCLUDED_ROLES[type],
            excluded = Logic.nilIfEmpty(Array.parseCommaSeparatedString(args.not_roles)) or DEFAULT_EXCLUDED_ROLES[type],
        }
    }
    if args.timeline then
        self.manualTimeline = self:readManualTimeline()
    else
        self.manualPlayers = self:readManualPlayers()
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

    mw.logObject(self.config)
end

function SquadAuto:readManualPlayers()
end

function SquadAuto:readManualTimeline()
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

            -- TODO: Skip this transfer if there is no relevant change
            -- E.g. this is grabbed a secondary team, but only main team changed
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

---comment
---@return table
function SquadAuto:selectEntries()
    return Array.filter(
        Array.flatMap(
            Array.extractValues(self.playersTeamHistory),
            FnUtil.curry(self._selectHistoryEntries, self)
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

            if not result then
                mw.logObject(entry, "Not included")
            end

            return result
        end
    )
end

---Returns a function that maps a set of transfers to a list of 
---SquadAutoPersons.
---Behavior depends on therent config:
---If the status is (inive, then at most one entry will be returned
---If the status is former(_inactive), there might be multiple entries returned
---If the type does not match, no entries are returned
---@param entries TeamHistoryEntry[]
---@return SquadAutoPerson[]
function SquadAuto:_selectHistoryEntries(entries)
    -- Select entries to match status
    if self.config.status == SquadUtils.SquadStatus.ACTIVE
            or self.config.status == SquadUtils.SquadStatus.INACTIVE then
        -- Only most recent transfer is relevant
        local last = entries[#entries]
        if last.type == SquadAuto.TransferType.CHANGE
                or last.type == SquadAuto.TransferType.JOIN then
            -- When the last transfer is a leave transfer, the person wouldn't be (in)active
            return {self:_mapToSquadAutoPerson(last)}
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
        leavedate = leaveEntry.date or '',
        leavedatedisplay = leaveEntry.dateDisplay,
        leavedateRef = leaveEntry.references,

        thisTeam = {
            --TODO
            team = joinEntry.toTeam,
            role = joinEntry.toRole,
            position = joinEntry.position
        },
        oldTeam = {
            --TODO
            team = joinEntry.fromTeam,
            role = joinEntry.fromRole,
        },
        newTeam = {
            team = leaveEntry.toTeam,
            role = leaveEntry.toRole,
        },

        -- From legacy: Prefer leaveEntry faction information
        faction = leaveEntry.faction or joinEntry.faction,
        race = leaveEntry.faction or joinEntry.faction
    }

    if leaveEntry and not entry.newTeam then
        --TODO: Fetch next team for person
    end

    return entry
end


return SquadAuto
