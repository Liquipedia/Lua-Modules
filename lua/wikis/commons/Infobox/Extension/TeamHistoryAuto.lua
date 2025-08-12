---
-- @Liquipedia
-- page=Module:Infobox/Extension/TeamHistoryAuto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--remaining issue: player joins/leaves same team with multiple roles on different dates (e.g. MarioMe LoL wiki)

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local TransferModel = Lua.import('Module:Transfer/Model')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local SPECIAL_ROLES = {
	'Retired',
	'Retirement',
	'Military',
	'Banned',
	'Producer',
	'Caster',
	'Admin',
	'Observer',
	'Host',
	'Talent',
	'League Operator',
	'Inactive'
}

---@class TeamHistoryAuto
---@operator call(table?): TeamHistoryAuto
---@field config {player: string, hasHeaderAndRefs: boolean?}
---@field transferList table[]
local TeamHistoryAuto = Class.new(function(self, args)
	---@type {player: string?}
	args = args or {}
	local configFromInfo = (Info.config.infoboxPlayer or {}).automatedHistory or {}
	self.config = {
		player = (args.player or mw.title.getCurrentTitle().subpageText):gsub('^%l', string.upper),
		hasHeaderAndRefs = configFromInfo.hasHeaderAndRefs,
	}
end)

---@return self
function TeamHistoryAuto:store()
	if not Namespace.isMain() then return self end
	Array.forEach(self.transferList, function(transfer, transferIndex)
		TeamHistoryAuto._checkForMissingLeaveDate(transfer, transferIndex, #self.transferList)
		local teamLink = self:_getTeamLink(transfer)
		if not teamLink and not transfer.role then return end

		mw.ext.LiquipediaDB.lpdb_datapoint('Team_'..transferIndex, Json.stringifySubTables{
			type = 'teamhistory',
			name = self.config.player,
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

	return self
end

---@param transfer table
---@param transferIndex integer
---@param numberOfRows integer
function TeamHistoryAuto._checkForMissingLeaveDate(transfer, transferIndex, numberOfRows)
	if transferIndex == numberOfRows or transfer.leaveDate then return end
	mw.ext.TeamLiquidIntegration.add_category('Players with potential incomplete transfer history')
end

---@param transfer table
---@return string?
function TeamHistoryAuto:_getTeamLink(transfer)
	if Logic.isEmpty(transfer.team) or not TeamTemplate.exists(transfer.team) then
		return Logic.nilIfEmpty(transfer.team)
	end
	local leaveDateCleaned = TeamHistoryAuto._adjustDate(transfer.leaveDate)
	local teamData = TeamTemplate.getRawOrNil(transfer.team, leaveDateCleaned) or {}

	return teamData.page
end

-- earlier date for fromteam to account for rebrands
---@param date string?
---@return string?
function TeamHistoryAuto._adjustDate(date)
	if Logic.isEmpty(date) then
		return date
	end
	---@cast date -nil

	local dateStruct = DateExt.parseIsoDate(date)
	dateStruct.day = dateStruct.day - 1
	return os.date('%Y-%m-%d', os.time(dateStruct)) --[[@as string]]
end

---@return self
function TeamHistoryAuto:fetch()
	self.transferList = TransferModel.getTeamHistoryForPerson{player = self.config.player, specialRoles = SPECIAL_ROLES}
	return self
end

return TeamHistoryAuto
