---
-- @Liquipedia
-- page=Module:Domain/TeamHistory/Model
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

--[[
Answers "was this person on the team, and when" by reading transfer records from the point of view
of one team.

Pure: it neither queries nor renders anything, and it knows nothing about how any feature displays
the result.
]]
local TeamHistory = {}

---@enum TransferType
TeamHistory.TransferType = {
	LEAVE = 'LEAVE',
	JOIN = 'JOIN',
	CHANGE = 'CHANGE',
}

---@enum TransferSide
TeamHistory.TransferSide = {
	FROM = 'from',
	TO = 'to',
}

--- One transfer, seen from the point of view of one team.
---@class (exact) TeamHistoryEntry
---@field pagename string
---@field displayname string
---@field flag string
---@field date string
---@field dateDisplay string?
---@field type TransferType
---@field references table<string, string>
---@field wholeTeam boolean
---@field position string?
---@field fromTeam string?
---@field fromRole string?
---@field toTeam string?
---@field toRole string?
---@field faction string?

local TransferType = TeamHistory.TransferType
local Side = TeamHistory.TransferSide

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
function TeamHistory.fromTransfer(record, teams)
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
---A person whose every transfer is irrelevant to the team never enters the history at all.
---@param records transfer[] ordered by date ascending
---@param teams string[] every team template that counts as the team
---@return table<string, TeamHistoryEntry[]>
function TeamHistory.fromTransfers(records, teams)
	---@type table<string, TeamHistoryEntry[]>
	local playersTeamHistory = {}

	Array.forEach(records, function(record)
		local entry = TeamHistory.fromTransfer(record, teams)
		if not entry then
			return
		end

		playersTeamHistory[record.player] = playersTeamHistory[record.player] or {}
		table.insert(playersTeamHistory[record.player], entry)
	end)

	return playersTeamHistory
end

return TeamHistory
