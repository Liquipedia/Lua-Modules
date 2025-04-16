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
local Namespace = Lua.import('Module:Namespace')
local Table = Lua.import('Module:Table')
local Team = Lua.import('Module:Team')
local TransferRef = Lua.import('Module:Transfer/References')

local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Abbr = HtmlWidgets.Abbr
local Fragment = HtmlWidgets.Fragment
local Span = HtmlWidgets.Span
local Tbl = HtmlWidgets.Table
local Td = HtmlWidgets.Td
local Th = HtmlWidgets.Th
local Tr = HtmlWidgets.Tr
local WidgetUtil = Lua.import('Module:Widget/Util')

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
local SPECIAL_ROLES_LOWER = Array.map(SPECIAL_ROLES, string.lower)
local LOAN = 'Loan'
local ONE_DAY = 86400
local ROLE_CONVERT = Lua.import('Module:Infobox/Extension/TeamHistoryAuto/RoleConvertData', {loadData = true})

local ROLE_CLEAN = Lua.requireIfExists('Module:TeamHistoryAuto/cleanRole', {loadData = true})
local POSITION_ICON_DATA = Lua.requireIfExists('Module:PositionIcon/data', {loadData = true})

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
		self:_checkForMissingLeaveDate(transfer, transferIndex)
		local teamLink = self:_getTeamLinkAndText(transfer)
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
---@param transferIndex integer
function TeamHistoryAuto:_checkForMissingLeaveDate(transfer, transferIndex)
	if transferIndex == #self.transferList or transfer.leaveDate then return end
	mw.ext.TeamLiquidIntegration.add_category('Players with potential incomplete transfer history')
end

---@param transfer table
---@return string?
---@return Widget
function TeamHistoryAuto:_getTeamLinkAndText(transfer)
	if Logic.isEmpty(transfer.team) and Table.includes(SPECIAL_ROLES_LOWER, (transfer.role or ''):lower()) then
		return nil, HtmlWidgets.B{children = {transfer.role}}
	elseif not mw.ext.TeamTemplate.teamexists(transfer.team) then
		return transfer.team, Link{link = transfer.team}
	end
	local leaveDateCleaned = TeamHistoryAuto._adjustDate(transfer.leaveDate)
	local teamData = mw.ext.TeamTemplate.raw(transfer.team, leaveDateCleaned) or {}

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
	if type(date) ~= 'string' or Logic.isEmpty(date) then
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
		children = WidgetUtil.collect(
			self.config.hasHeaderAndRefs and self:_header() or nil,
			Array.map(self.transferList, FnUtil.curry(self._row, self))
		)
	}
end

---@return Widget
function TeamHistoryAuto:_header()
	local makeQueryFormLink = function()
		local linkParts = {
			tostring(mw.uri.fullUrl('Special:RunQuery/Transfer_history')),
			'?pfRunQueryFormName=Transfer+history&',
			mw.uri.buildQueryString{['Transfer_query[players]'] = self.config.player},
			'&wpRunQuery=Run+query'
		}
		return Link{
			link = table.concat(linkParts),
			children = {'q'},
		}
	end

	return Tr{children = {
		Th{children = {'Join'}},
		Th{
			css = {['padding-left'] = '5px'},
			children = {'Leave'},
		},
		Th{
			css = {['padding-left'] = '5px'},
			children = {
				'Team',
				Span{
					css = {float = 'right', ['font-size'] = '90%', ['font-weight'] = '500'},
					children = {
						mw.text.nowiki('['),
						makeQueryFormLink(),
						mw.text.nowiki(']'),
					},
				},
			},
		},
	}}
end

---@param transfer table
---@return Widget
function TeamHistoryAuto:_row(transfer)
	local _, teamText = self:_getTeamLinkAndText(transfer)

	---@type Widget|string?
	local role = transfer.role
	if role then
		local splitRole = mw.text.split(role --[[@as string]], ' ')
		local roleData = ROLE_CONVERT[transfer.role:lower()] or ROLE_CONVERT[splitRole[#splitRole]:lower()]
		if roleData.empty then
			role = nil
		else
			role = roleData and Abbr(roleData) or transfer.role
		end
	end
	if role == LOAN then
		teamText = '&#8250;&nbsp;' .. teamText
	end
	---@type string|Widget
	local teamDisplay = teamText
	if role then
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
	if POSITION_ICON_DATA then
		local position = (transfer.position or ''):lower()
		positionIcon = (POSITION_ICON_DATA[position] or POSITION_ICON_DATA['']) .. '&nbsp;'
	end

	local leaveateDisplay = self:_buildLeaveDateDisplay(transfer)

	if not self.config.hasHeaderAndRefs then
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

	return Tr{children = {
		Td{
			classes = {'th-mono'},
			css = {['white-space'] = 'nowrap', ['vertical-align'] = 'top'},
			children = {
				transfer.joinDateDisplay,
				TeamHistoryAuto._displayRef(transfer.reference.join, transfer.joinDateDisplay)
			},
		},
		Td{
			classes = {'th-mono'},
			css = {['white-space'] = 'nowrap', ['vertical-align'] = 'top', ['padding-left'] = '5px'},
			children = {
				leaveateDisplay,
				TeamHistoryAuto._displayRef(transfer.reference.leave, transfer.leaveDateDisplay)
			},
		},
		Td{
			css = {['padding-left'] = '5px'},
			children = WidgetUtil.collect(
				positionIcon and (positionIcon .. '&nbsp;') or nil,
				teamDisplay
			),
		},
	}}
end

---@param references table[]
---@param date string
---@return Widget?
function TeamHistoryAuto._displayRef(references, date)
	local refs = Array.map(TransferRef.fromStorageData(references), function(reference)
		return reference.link and TransferRef.useReference(reference, date) or nil
	end)

	if Logic.isEmpty(refs) then return end

	return Fragment{children = {
		Span{
			css = {['font-size'] = '50%'},
			children = {'&thinsp;'},
		},
		refs
	}}
end

---@param transfer table
---@return string|Widget?
function TeamHistoryAuto:_buildLeaveDateDisplay(transfer)
	if transfer.leaveDateDisplay then return transfer.leaveDateDisplay end

	local lowerCasedRole = (transfer.role or ''):lower()
	if lowerCasedRole == 'military' or not Table.includes(SPECIAL_ROLES_LOWER, (transfer.role or ''):lower()) then
		return Span{
			css = {['font-weight'] = 'bold'},
			children = {'Present'}
		}
	end
end

---@return transfer[]
function TeamHistoryAuto:_query()
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDate),
		ConditionNode(ColumnName('player'), Comparator.eq, self.config.player),
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('toteam'), Comparator.neq, ''),
			Array.map(SPECIAL_ROLES, function(role)
				return ConditionNode(ColumnName('role2'), Comparator.eq, role)
			end),
			Array.map(SPECIAL_ROLES, function(role)
				return ConditionNode(ColumnName('role2'), Comparator.eq, role:lower())
			end),
		},
	}

	return mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = conditions:toString(),
		order = 'date asc',
		limit = 5000,
		query = 'pagename, fromteam, toteam, role1, role2, date, extradata, reference'
	})
end

---@return self
function TeamHistoryAuto:fetch()
	self.transferList = {}
	Array.forEach(self:_query(), FnUtil.curry(self._processTransfer, self))

	if ROLE_CLEAN then
		Array.forEach(self.transferList, function(transfer)
			transfer.role = ROLE_CLEAN[(transfer.role or ''):lower()]
		end)
	end

	self.transferList = Array.map(self.transferList, FnUtil.curry(TeamHistoryAuto._completeTransfer, self))

	-- Sort table by joinDate/leaveDate
	table.sort(self.transferList, function(transfer1, transfer2)
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

	return self
end

---@param transfer transfer
function TeamHistoryAuto:_processTransfer(transfer)
	local extraData = transfer.extradata
	local transferDate = DateExt.toYmdInUtc(transfer.date)
	local transferList = self.transferList

	if Logic.isNotEmpty(extraData.toteamsec) then
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
				reference = { join = transfer.reference, leave = '' },
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
				reference = { join = transfer.reference, leave = '' },
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
			reference = { join = transfer.reference, leave = '' },
		})
	end
end

---@param transfer table
---@return table
function TeamHistoryAuto:_completeTransfer(transfer)
	local leaveTransfers = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = self:_buildConditions(transfer),
		order = 'date asc',
		query = 'toteam, role2, date, extradata, reference'
	})

	local hasLeaveDate = function(leaveTransfer)
		local extraData = leaveTransfer.extradata

		return (
			extraData.toteamsec ~= transfer.team or
			extraData.role2sec ~= (transfer.role or '')
		) and (
			leaveTransfer.toteam ~= transfer.team or
			leaveTransfer.role2 ~= (transfer.role or '') or
			extraData.icon2 ~= transfer.position
		)
	end

	for _, leaveTransfer in ipairs(leaveTransfers) do
		if hasLeaveDate(leaveTransfer) then
			transfer.leaveDate = DateExt.toYmdInUtc(leaveTransfer.date)
			transfer.leaveDateDisplay = leaveTransfer.extradata.dispaydate or transfer.leaveDate
			transfer.reference.leave = leaveTransfer.reference

			return transfer
		end
	end

	return transfer
end

---@param transfer table
---@return string
function TeamHistoryAuto:_buildConditions(transfer)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.ge, transfer.joinDate),
		ConditionNode(ColumnName('player'), Comparator.eq, self.config.player),
	}

	local historicalNames = Team.queryHistoricalNames(transfer.team)

	local buildFromConditions = function(teamField, roleField)
		local fromConditions = ConditionTree(BooleanOperator.any):add(Array.map(historicalNames, function(team)
			return ConditionNode(ColumnName(teamField), Comparator.eq, team)
		end))

		if ROLE_CLEAN and not transfer.role then
			return fromConditions
		end

		return ConditionTree(BooleanOperator.all):add{
			fromConditions,
			ConditionNode(ColumnName(roleField), Comparator.eq, transfer.role or ''),
		}
	end

	if Logic.isNotEmpty(historicalNames) then
		conditions:add(ConditionTree(BooleanOperator.any):add{
			buildFromConditions('fromteam', 'role1'),
			buildFromConditions('extradata_fromteamsec', 'extradata_role1sec'),
		})
	elseif Table.includes(SPECIAL_ROLES_LOWER, (transfer.role or ''):lower()) then
		conditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('role1'), Comparator.eq, transfer.role),
			ConditionNode(ColumnName('role1'), Comparator.eq, transfer.role:lower()),
		})
	end

	return conditions:toString()
end

return TeamHistoryAuto
