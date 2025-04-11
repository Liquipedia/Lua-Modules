---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Extension/TeamHistoryAuto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--remaining issue: player joins/leaves same team with multiple roles on different dates (e.g. MarioMe LoL wiki)

local Class = require('Module:Class')
local Lua = require('Module:Lua')


local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Team = Lua.import('Module:Team')

local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Span = HtmlWidgets.Span
local Tbl = HtmlWidgets.Table
local Td = HtmlWidgets.Td
local Tr = HtmlWidgets.Tr
local WidgetUtil = Lua.import('Module:Widget/Util')

local LANG = mw.language.getContentLanguage()
local SPECIAL_ROLES = {'Retired', 'Retirement', 'Military'}
local SPECIAL_ROLES_LOWER = Array.map(SPECIAL_ROLES, string.lower)
local LOAN = 'Loan'
local ONE_DAY = 86400

local ROLE_CONVERT = Lua.requireIfExists('Module:TeamHistoryAuto/role', {loadData = true})
local ROLE_CLEAN = Lua.requireIfExists('Module:TeamHistoryAuto/cleanRole', {loadData = true})

---@class TeamHistoryAuto
---@operator call(table?): TeamHistoryAuto
---@field config {player: string, showRole: boolean, store: boolean, specialRoles: boolean, iconModule: table?}
---@field transferList table[]
local TeamHistoryAuto = Class.new(function(self, args)
	-- specialRoles is a stringified bool to support manual input on 9 val pages ...
	---@type {player: string?, specialRoles: string?}
	args = args or {}
	local configFromInfo = (Info.config.infoboxPlayer or {}).automatedHistory or {}
	self.config = {
		player = (args.player or mw.title.getCurrentTitle().subpageText):gsub('^%l', string.upper),
		showRole = Logic.nilOr(configFromInfo.showRole, true),
		store = configFromInfo.store,
		specialRoles = Logic.nilOr(Logic.readBoolOrNil(args.specialRoles), configFromInfo.specialRoles, false),
		iconModule = configFromInfo.iconModule and Lua.import(configFromInfo.iconModule),
	}
end)

---@return self
function TeamHistoryAuto:fetch()

end

---@return self
function TeamHistoryAuto:store()
	if not self.config.store then return self end

	Array.forEach(self.transferList, function(transfer, transferIndex)
		local teamLink = TeamHistoryAuto._getTeamLinkAndText(transfer)
		if not teamLink and not transfer.role then return end

		mw.ext.LiquipediaDB.lpdb_datapoint('Team_'..transferIndex, {
			type = 'teamhistory',
			name = self.config.player,
			information = teamLink,
			extradata = mw.ext.LiquipediaDB.lpdb_create_json({
				joindate = transfer.joinDate,
				leavedate = transfer.leaveDate or '2999-01-01',
				teamcount = transferIndex,
				role = transfer.role,
				auto = 1,
			})
		})
	end)

	return self
end

---@param transfer table
---@return string?
---@return Widget
function TeamHistoryAuto._getTeamLinkAndText(transfer)
	if Logic.isEmpty(transfer.team) and Table.includes(SPECIAL_ROLES_LOWER, (transfer.role or ''):lower()) then
		return nil, HtmlWidgets.B{children = {transfer.role}}
	elseif not mw.ext.TeamTemplate.teamexists(transfer.team) then
		return transfer.team, Link{link = transfer.team}
	end
	local leaveDateCleaned = TeamHistoryAuto._adjustDate(transfer.leaveDate)
	local teamData = mw.ext.TeamTemplate.raw(transfer.team, leaveDateCleaned) or {}
	local shortenedTeamName = teamData.name
	if string.len(shortenedTeamName) <= 17 then

	end
	return teamData.page, Link{
		link = teamData.page,
		children = {TeamHistoryAuto._shortenTeamName(teamData)}
	}
end

---@param teamData {name: string, bracketname: string, shortname: string}
---@return string
function TeamHistoryAuto._shortenTeamName(teamData)
	local teamName = teamData.name
	if string.len(teamName) <= 17 then
		return teamName
	end

	teamName = teamData.bracketname or teamData.name
	if string.len(teamName) <= 17 then
		return teamName
	end
	return teamData.shortname or teamData.name
end

-- earlier date for fromteam to account for rebrands
---@param date string?
---@return string?
function TeamHistoryAuto._adjustDate(date)
	if type(date) ~= 'string' or String.isEmpty(date) then
		return date
	end

	local year, month, day = date:match('(%d+)-(%d+)-(%d+)')
	local timeStamp = os.time{day = day, month = month, year = year}
	return os.date('%Y-%m-%d', timeStamp - ONE_DAY) --[[@as string]]
end

---@return Widget?
function TeamHistoryAuto:build()
	if Logic.isEmpty(self.transferList) then return end

	return Tbl{
		css = {width = '100%', ['text-align'] = 'left'},
		children = Array.map(self.transferList, FnUtil.curry(TeamHistoryAuto._row, self))
	}
end

---@param transfer table
---@return Widget
function TeamHistoryAuto:_row(transfer)
	local teamLink, teamText = TeamHistoryAuto._getTeamLinkAndText(transfer)

	local role = transfer.role
	if ROLE_CONVERT and role then
		local splitRole = mw.text.split(role, ' ')
		role = ROLE_CONVERT[transfer.role:lower()] or ROLE_CONVERT[splitRole[#splitRole]:lower()] or transfer.role
	end
	if role == LOAN then
		teamText = '&#8250;&nbsp;' .. teamText
	end
	---@type string|Widget
	local teamDisplay = teamText
	if role and self.config.showRole then
		teamDisplay = Span{
			css = {['padding-left'] = '3px', ['font-style'] = 'italic'},
			children = {
				'(',
				role
				')',
			}
		}
	end

	local positionIcon
	if self.config.iconModule then
		local position = (transfer.position or ''):lower()
		positionIcon = (self.config.iconModule[position] or self.config.iconModule['']) .. '&nbsp;'
	end

	local leaveateDisplay = TeamHistoryAuto._buildLeaveDateDisplay(transfer)

	return Tr{children = {
		Td{
			classes = {'th-mono'},
			css = {float = 'left', width = '50%', ['font-style'] = 'italic'},
			children = {
				transfer.joinDateDisplay,
				leaveateDisplay and ' &#8212; ' or nil,
				leaveateDisplay,
			},
		},
		Td{
			css = {float = 'right', width = '50%'},
			children = WidgetUtil.collect(
				positionIcon,
				teamDisplay
			),
		},
	}}
end

---@param transfer table
---@return string|Widget?
function TeamHistoryAuto._buildLeaveDateDisplay(transfer)
	if transfer.leaveDateDisplay then return transfer.leaveDateDisplay end

	local lowerCasedRole = (transfer.role or ''):lower()
	if lowerCasedRole == 'military' or not Table.includes(SPECIAL_ROLES_LOWER, (transfer.role or ''):lower()) then
		return Span{
			css = {['font-weight'] = 'bold'},
			children = {'Present'}
		}
	end
end










---[[ OLD STUFF ]]


function TeamHistoryAuto._buildTransferList()
	local roleConditions = _config.specialRoles and (' OR ' .. table.concat(Array.map(SPECIAL_ROLES, function(role)
		return '[[role2::' .. role .. ']] OR [[role2::' .. role:lower() .. ']]'
	end), ' OR ')) or ''

	local transferData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = '[[player::' .. _config.player .. ']] AND ([[toteam::>]]' .. roleConditions .. ') AND [[date::>' .. DateExt.defaultDate .. ']]',
		order = 'date asc',
		limit = 5000,
		query = 'pagename, fromteam, toteam, role1, role2, date, extradata'
	}) --[[@as transfer[]?]]

	local transferList = {}

	-- Process transfer (team, role, join date)
	for _, transfer in ipairs(transferData or {}) do
		-- need it like this; can not insert directly, else we get errors in some edge cases
		local transferEntry = TeamHistoryAuto._processTransfer(transfer, transferList)
	end

	-- release transferData to free up memory
	transferData = nil

	for _, transfer in pairs(transferList) do
		if _config.roleClean then
			transfer.role = _config.roleClean[(transfer.role or ''):lower()]
		end
		TeamHistoryAuto._completeTransfer(transfer)
	end

	-- Sort table by joinDate/leaveDate
	table.sort(transferList, function(transfer1, transfer2)
		if transfer1.joinDate == transfer2.joinDate then
			if transfer1.role == LOAN and transfer2.role ~= LOAN then
				return false
			elseif transfer2.role == LOAN and transfer1.role ~=LOAN then
				return true
			end

			return (transfer1.leaveDate or '') < (transfer2.leaveDate or '')
		end

		return transfer1.joinDate < transfer2.joinDate
	end)

	return transferList
end

function TeamHistoryAuto._processTransfer(transfer, transferList)
	local extraData = transfer.extradata
	local transferDate = LANG:formatDate('Y-m-d', transfer.date)

	if String.isNotEmpty(extraData.toteamsec) then
		-- transfer includes multiple teams (Tl:Transfer_row |team2_2, |role2_2)
		if (extraData.toteamsec ~= transfer.fromteam or extraData.role2sec ~= transfer.role1) and
			(extraData.toteamsec ~= extraData.fromteamsec or extraData.role2sec ~= extraData.role1sec) then
			-- secondary transfer
			table.insert(transferList, {
				team = extraData.toteamsec,
				role = extraData.role2sec,
				position = extraData.icon2,
				joinDate = transferDate,
				joinDateDisplay = extraData.displaydate or transferDate,
			})
		end

		if (transfer.toteam ~= transfer.fromteam or transfer.role2 ~= transfer.role1) and
			(transfer.toteam ~= extraData.fromteamsec or transfer.role2 ~= extraData.role1sec) then
			-- primary transfer
			table.insert(transferList, {
				team = transfer.toteam,
				role = transfer.role2,
				position = extraData.icon2,
				joinDate = transferDate,
				joinDateDisplay = extraData.displaydate or transferDate,
			})
		end
	elseif transfer.toteam ~= extraData.fromteamsec or transfer.role2 ~= extraData.role1sec then
		-- classic transfer
		table.insert(transferList, {
			team = transfer.toteam,
			role = transfer.role2,
			position = extraData.icon2,
			joinDate = transferDate,
			joinDateDisplay = extraData.displaydate or transferDate,
		})
	end
end

function TeamHistoryAuto._completeTransfer(transfer)
	local leaveTransfers = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = TeamHistoryAuto._buildConditions(transfer),
		order = 'date asc',
		query = 'toteam, role2, date, extradata'
	})

	for _, leaveTransfer in ipairs(leaveTransfers) do
		local extraData = leaveTransfer.extradata

		if
			(leaveTransfer.toteam ~= transfer.team or leaveTransfer.role2 ~= (transfer.role or '') or extraData.icon2 ~= transfer.position)
			and (extraData.toteamsec ~= transfer.team or extraData.role2sec ~= (transfer.role or '')) then

			transfer.leaveDate = LANG:formatDate('Y-m-d', leaveTransfer.date)
			transfer.leaveDateDisplay = extraData.displaydate or transfer.leaveDate

			break
		end
	end
end

function TeamHistoryAuto._buildConditions(transfer)
	local historicalNames = Team.queryHistoricalNames(transfer.team)

	local conditions = {
		'[[player::' .. _config.player .. ']]',
		'([[date::>' .. transfer.joinDate .. ']] OR [[date::' .. transfer.joinDate .. ']])'
	}

	if historicalNames then
		local fromCondition = Array.map(historicalNames, function(team) return '[[fromteam::' .. team .. ']]' end)
		fromCondition = '(' .. table.concat(fromCondition, ' OR ') .. ')'
		if transfer.role then
			fromCondition = fromCondition .. ' AND [[role1::' .. transfer.role .. ']]'
		elseif not _config.roleClean then
			fromCondition = fromCondition .. ' AND [[role1::]]'
		end

		local fromConditionSecondary = Array.map(historicalNames, function(team) return '[[extradata_fromteamsec::' .. team .. ']]' end)
		fromConditionSecondary = '(' .. table.concat(fromConditionSecondary, ' OR ') .. ')'
		if transfer.role then
			fromConditionSecondary = fromConditionSecondary .. ' AND [[extradata_role1sec::' .. transfer.role .. ']]'
		elseif not _config.roleClean then
			fromConditionSecondary = fromConditionSecondary .. ' AND [[extradata_role1sec::]]'
		end

		table.insert(conditions, '(' .. fromCondition .. ' OR ' .. fromConditionSecondary .. ')')
	elseif Table.includes(SPECIAL_ROLES_LOWER, (transfer.role or ''):lower()) then
		table.insert(conditions, '[[role1::' .. transfer.role .. ']] OR [[role1::' .. transfer.role:lower() .. ']]')
	end

	return table.concat(conditions, ' AND ')
end


return TeamHistoryAuto
