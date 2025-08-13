---
-- @Liquipedia
-- page=Module:Infobox/Extension/TeamHistory/Store
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Variables = Lua.import('Module:Variables')

local TeamHistoryStore = {}

---@param transferList any
---@param player string?
function TeamHistoryStore.store(transferList, player)
	if not Namespace.isMain() then return end

	player = player or String.upperCaseFirst(mw.title.getCurrentTitle().subpageText)

	local offset = tonumber(Variables.varDefault('teamhistory_index')) or 0

	Array.forEach(transferList, function(transfer, transferIndex)
		transferIndex = transferIndex + offset
		TeamHistoryStore._checkForMissingLeaveDate(transfer, transferIndex, offset + #transferList)
		local teamLink = TeamHistoryStore._getTeamLink(transfer)
		if not teamLink and not transfer.role then return end

		mw.ext.LiquipediaDB.lpdb_datapoint('Team_'.. transferIndex, Json.stringifySubTables{
			type = 'teamhistory',
			name = player,
			information = teamLink,
			extradata = {
				joindate = transfer.joinDate,
				leavedate = transfer.leaveDate or '2999-01-01',
				teamcount = transferIndex,
				role = transfer.role,
				auto = 1,
			},
		})
	end)
end

---@param transfer table
---@param transferIndex integer
---@param numberOfRows integer
function TeamHistoryStore._checkForMissingLeaveDate(transfer, transferIndex, numberOfRows)
	if transferIndex == numberOfRows or transfer.leaveDate then return end
	mw.ext.TeamLiquidIntegration.add_category('Players with potential incomplete transfer history')
end

---@param transfer table
---@return string?
function TeamHistoryStore._getTeamLink(transfer)
	if Logic.isEmpty(transfer.team) or not TeamTemplate.exists(transfer.team) then
		return Logic.nilIfEmpty(transfer.team)
	end
	local leaveDateCleaned = TeamHistoryStore._adjustDate(transfer.leaveDate)
	local teamData = TeamTemplate.getRawOrNil(transfer.team, leaveDateCleaned) or {}

	return teamData.page
end

-- earlier date for fromteam to account for rebrands
---@param date string?
---@return string?
function TeamHistoryStore._adjustDate(date)
	if Logic.isEmpty(date) then
		return date
	end
	---@cast date -nil

	local dateStruct = DateExt.parseIsoDate(date)
	dateStruct.day = dateStruct.day - 1
	return os.date('%Y-%m-%d', os.time(dateStruct)) --[[@as string]]
end

return TeamHistoryStore
