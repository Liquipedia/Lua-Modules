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
local FnUtil = Lua.import('Module:FnUtil')
local Info = Lua.import('Module:Info', {loadData = true})
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Roles = Lua.import('Module:Roles')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local TransferModel = Lua.import('Module:Transfer/Model')
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
local LOAN = 'Loan'

local POSITION_ICON_DATA = Lua.requireIfExists('Module:PositionIcon/data', {loadData = true})

-- todo at a later date: move into standardized role data where reasonable or kick
local NOT_YET_IN_ROLES_DATA = {
	['coach/analyst'] = {display = 'Coach/Analyst', abbreviation = 'C./A.'},
	['coach and analyst'] = {display = 'Coach/Analyst', abbreviation = 'C./A.'},
	['overall coach'] = {display = 'Overall Coach', abbreviation = 'OC.'},
	['manager and analyst'] = {display = 'Manager/Analyst', abbreviation = 'M./A.'},
	['manager/analyst'] = {display = 'Manager/Analyst', abbreviation = 'M./A.'},
	['general manager'] = {display = 'General Manager', abbreviation = 'GM.'},
	['assistant general manager'] = {display = 'Assistant General Manager', abbreviation = 'AGM.'},
	['team manager'] = {display = 'Team Manager', abbreviation = 'TM.'},
	['assistant team manager'] = {display = 'Assistant Team Manager', abbreviation = 'ATM.'},
	substitute = {display = 'Substitute', abbreviation = 'Sub.'},
	inactive = {display = 'Inactive', abbreviation = 'Ia.'},
	['training advisor'] = {display = 'Training Advisor', abbreviation = 'TA.'},
	['founder & training director'] = {display = 'Founder & Training Director', abbreviation = 'F. & TD.'},
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
		local teamLink = self:_getTeamLinkAndText(transfer)
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
---@return Widget
function TeamHistoryAuto:_getTeamLinkAndText(transfer)
	if Logic.isEmpty(transfer.team) and Table.includes(SPECIAL_ROLES, transfer.role) then
		return nil, HtmlWidgets.B{children = {transfer.role}}
	elseif not TeamTemplate.exists(transfer.team) then
		return transfer.team, Link{link = transfer.team}
	end
	local leaveDateCleaned = TeamHistoryAuto._adjustDate(transfer.leaveDate)
	local teamData = TeamTemplate.getRawOrNil(transfer.team, leaveDateCleaned) or {}

	return teamData.page, Link{
		link = teamData.page,
		children = {TeamHistoryAuto._getTeamDisplayName(teamData)}
	}
end

---@param teamData {name: string, bracketname: string, shortname: string}
---@return string
function TeamHistoryAuto._getTeamDisplayName(teamData)
	if string.len(teamData.name) <= 17 then
		return teamData.name
	elseif string.len(teamData.bracketname) <= 17 then
		return teamData.bracketname
	else
		return teamData.shortname or teamData.name
	end
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
		return Link{
			link = tostring(mw.uri.fullUrl('Special:RunQuery/Transfer history', {
				pfRunQueryFormName = 'Transfer history',
				['Transfer query[players]'] = self.config.player,
				wpRunQuery ='Run query'
			})),
			linktype = 'external',
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
	local role = Logic.nilIfEmpty(transfer.role)
	if role then
		local splitRole = Array.parseCommaSeparatedString(role --[[@as string]], ' ')
		local lastSplitRole = splitRole[#splitRole]:lower()
		local roleData = Roles.All[transfer.role:lower()] or Roles.All[lastSplitRole]
			or NOT_YET_IN_ROLES_DATA[transfer.role:lower()] or NOT_YET_IN_ROLES_DATA[lastSplitRole] or {}
		if roleData.doNotShowInHistory then
			role = nil
		elseif roleData.abbreviation then
			role = roleData and Abbr{title = roleData.display, children = {roleData.abbreviation}}
		end
	end
	if role == LOAN then
		teamText = '&#8250;&nbsp;' .. teamText
	end
	---@type string|Widget|(string|Widget)[]
	local teamDisplay = teamText
	if role then
		teamDisplay = {
			teamText,
			Span{
				css = {['padding-left'] = '3px', ['font-style'] = 'italic'},
				children = {
					'(',
					role,
					')',
				},
			},
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

	return Fragment{children = WidgetUtil.collect(
		Span{
			css = {['font-size'] = '50%'},
			children = {'&thinsp;'},
		},
		refs
	)}
end

---@param transfer table
---@return string|Widget?
function TeamHistoryAuto:_buildLeaveDateDisplay(transfer)
	if transfer.leaveDateDisplay then return transfer.leaveDateDisplay end

	if not Table.includes(SPECIAL_ROLES, transfer.role) then
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
	self.transferList = TransferModel.getTeamHistoryForPerson{player = self.config.player, specialRoles = SPECIAL_ROLES}
	return self
end

return TeamHistoryAuto
