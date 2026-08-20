---
-- @Liquipedia
-- page=Module:Features/Squad/Lib/History
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local SquadTypes = Lua.import('Module:Features/Squad/Types')

local TransferType = SquadTypes.TransferType
local Side = SquadTypes.TransferSide
local ROLE_INACTIVE = SquadTypes.ROLE_INACTIVE

--- Answers "was this person on the team, and when" from transfer records.
--- Pure: it neither queries nor renders anything, it only reads records and returns history.
local SquadHistory = {}

--- A transfer that could not be fitted into the history. The caller decides how to report it.
---@class SquadHistoryWarning
---@field reason string
---@field entry TeamHistoryEntry

---@class SquadHistorySelection
---@field stints SquadStint[]
---@field warnings SquadHistoryWarning[]
---@field hasInactiveEntry boolean whether a transfer took someone off the active squad

---Checks whether a given team is one of the teams the history is built for
---@param teams string[]
---@param team string?
---@return boolean
local function isCurrentTeam(teams, team)
	if not team then
		return false
	end
	return Array.any(teams, FnUtil.curry(Operator.eq, team))
end

---Finds the team on one side of a transfer, if it is one of the teams the history is built for
---@param side TransferSide
---@param transfer transfer
---@param teams string[]
---@return string? team
---@return boolean isMain whether the team was found in the main rather than the secondary field
local function parseRelevantTeam(side, transfer, teams)
	local mainTeam = transfer[side .. 'teamtemplate']
	if mainTeam and isCurrentTeam(teams, mainTeam) then
		return mainTeam, true
	end

	local secondaryTeam = transfer.extradata[side .. 'teamsectemplate']
	if secondaryTeam and isCurrentTeam(teams, secondaryTeam) then
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
			return TransferType.CHANGE
		end
		return TransferType.LEAVE
	end
	return TransferType.JOIN
end

---Parses the relevant role for the current team from a transfer
---@param side TransferSide
---@param transfer transfer
---@param team string?
---@param isMain boolean
---@return string?
local function parseRelevantRole(side, transfer, team, isMain)
	if not team then
		return nil
	end

	if isMain then
		return side == Side.FROM and transfer.role1 or transfer.role2
	else
		return side == Side.FROM and transfer.extradata.role1sec or transfer.extradata.role2sec
	end
end

---Reads a single transfer record from the point of view of a team.
---Returns nothing when the transfer does not change anything for that team.
---@param record transfer
---@param teams string[] every team template that counts as the team
---@return TeamHistoryEntry?
function SquadHistory.fromTransfer(record, teams)
	record.extradata = record.extradata or {}

	local relevantFromTeam, isFromMain = parseRelevantTeam(Side.FROM, record, teams)
	local relevantToTeam, isToMain = parseRelevantTeam(Side.TO, record, teams)
	local transferType = getTransferType(relevantFromTeam, relevantToTeam)

	local fromRole = parseRelevantRole(Side.FROM, record, relevantFromTeam, isFromMain)
	local toRole = parseRelevantRole(Side.TO, record, relevantToTeam, isToMain)

	-- For leave transfers: Pass on new team for display as next team
	if transferType == TransferType.LEAVE and Logic.isEmpty(relevantToTeam) then
		if isFromMain then
			relevantToTeam = Logic.nilIfEmpty(record.toteamtemplate)
			toRole = Logic.nilIfEmpty(record.role2)
		else
			relevantToTeam = Logic.nilIfEmpty(record.extradata.toteamsectemplate)
			toRole = Logic.nilIfEmpty(record.extradata.role2sec)
		end
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
		fromRole = fromRole,
		toRole = toRole,

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
		return nil
	end

	return entry
end

---Groups transfer records into a team history per person.
---A person whose every transfer was irrelevant is still present, with an empty history.
---@param records transfer[] ordered by date ascending
---@param teams string[] every team template that counts as the team
---@return table<string, TeamHistoryEntry[]>
function SquadHistory.fromTransfers(records, teams)
	---@type table<string, TeamHistoryEntry[]>
	local playersTeamHistory = {}

	Array.forEach(records, function(record)
		playersTeamHistory[record.player] = playersTeamHistory[record.player] or {}

		local entry = SquadHistory.fromTransfer(record, teams)
		if not entry then
			return
		end

		table.insert(playersTeamHistory[record.player], entry)
	end)

	return playersTeamHistory
end

---Walks a person's team history as join -> [inactive] -> leave and returns the stints it found.
---@private
---@param entries TeamHistoryEntry[]
---@return SquadHistorySelection
function SquadHistory._selectFormerStints(entries)
	local stints = {}
	local warnings = {}
	local hasInactiveEntry = false

	local joinEntry, inactiveEntry

	Array.forEach(entries, function (entry)
		if entry.type == TransferType.JOIN then
			if joinEntry then
				table.insert(warnings, {reason = 'Invalid entry: Duplicate JOIN. Skipping', entry = entry})
				return
			end
			joinEntry = entry
			return
		end
		if not joinEntry then
			table.insert(warnings, {reason = 'Invalid entry: Missing previous JOIN. Skipping', entry = entry})
			return
		end

		if entry.type == TransferType.CHANGE and entry.toRole == ROLE_INACTIVE then
			-- FORMER_INACTIVE enables the Inactive Date display
			hasInactiveEntry = true
			inactiveEntry = entry
			return
		end

		table.insert(stints, {joinEntry = joinEntry, inactiveEntry = inactiveEntry, leaveEntry = entry})
		joinEntry = nil
		inactiveEntry = nil

		if entry.type == TransferType.CHANGE then
			joinEntry = entry
		end
	end)

	return {stints = stints, warnings = warnings, hasInactiveEntry = hasInactiveEntry}
end

---Selects the stints of one person's team history that belong in a squad table of a given status.
---For (in)active tables at most one stint is returned, for former tables there may be several.
---An unrecognized status selects nothing, which is how an unreadable status argument ends up.
---@param entries TeamHistoryEntry[]
---@param squadStatus SquadStatus?
---@return SquadHistorySelection
function SquadHistory.selectStints(entries, squadStatus)
	local nothing = {stints = {}, warnings = {}, hasInactiveEntry = false}

	if squadStatus == SquadTypes.SquadStatus.ACTIVE then
		-- Only most recent transfer is relevant
		local last = entries[#entries]
		if not last then
 			return nothing
 		end
		if (last.type == TransferType.CHANGE or last.type == TransferType.JOIN)
				and last.toRole ~= ROLE_INACTIVE then
			-- When the last transfer is a leave transfer, or the role is inactive, the person wouldn't be active
			return {stints = {{joinEntry = last}}, warnings = {}, hasInactiveEntry = false}
		end
	end

	if squadStatus == SquadTypes.SquadStatus.INACTIVE then
		local last, secondToLast = entries[#entries], entries[#entries - 1]
		if secondToLast and last.type == TransferType.CHANGE and last.toRole == ROLE_INACTIVE then
			return {
				stints = {{joinEntry = secondToLast, inactiveEntry = last}},
				warnings = {},
				hasInactiveEntry = false,
			}
		end
	end

	if squadStatus == SquadTypes.SquadStatus.FORMER or squadStatus == SquadTypes.SquadStatus.FORMER_INACTIVE then
		return SquadHistory._selectFormerStints(entries)
	end

	return nothing
end

return SquadHistory
