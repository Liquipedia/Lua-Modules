---
-- @Liquipedia
-- page=Module:Widget/Infobox/TeamHistory/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Roles = Lua.import('Module:Roles')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local TransferRef = Lua.import('Module:Transfer/References')
local Variables = Lua.import('Module:Variables')
local Widget = Lua.import('Module:Widget')

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

local SPECIAL_ROLES = Lua.import('Module:Infobox/Extension/TeamHistory/SpecialRoles', {loadData = true})
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

local HAS_REFS = ((Info.config.infoboxPlayer or {}).automatedHistory or {}).hasHeaderAndRefs

---@class TeamHistoryDisplayWidget: Widget
---@operator call(table): TeamHistoryDisplayWidget
---@field props {transferList: TransferSpan[], player: string}
local TeamHistoryDisplay = Class.new(Widget)
TeamHistoryDisplay.defaultProps = {
	transferList = {},
	player = String.upperCaseFirst(mw.title.getCurrentTitle().subpageText),
}

---@return Widget?
function TeamHistoryDisplay:render()
	if Logic.isEmpty(self.props.transferList) then return end

	local offset = tonumber(Variables.varDefault('teamhistory_index')) or 0
	Variables.varDefine('teamhistory_index', offset + #self.props.transferList)

	return Tbl{
		css = {width = '100%', ['text-align'] = 'left'},
		children = WidgetUtil.collect(
			HAS_REFS and offset == 0 and self:_header() or nil,
			Array.map(self.props.transferList, FnUtil.curry(self._row, self))
		)
	}
end

---@return Widget
function TeamHistoryDisplay:_header()
	local makeQueryFormLink = function()
		return Link{
			link = tostring(mw.uri.fullUrl('Special:RunQuery/Transfer history', {
				pfRunQueryFormName = 'Transfer history',
				['Transfer query[players]'] = self.props.player,
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

---@param transfer TransferSpan
---@return Widget
function TeamHistoryDisplay:_row(transfer)
	local teamText = self:_getTeamText(transfer)

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
	---@type (string|Widget)[]
	local teamDisplay = {teamText}
	if role then
		table.insert(teamDisplay,
			Span{
				css = {['padding-left'] = '3px', ['font-style'] = 'italic'},
				children = {
					'(',
					role,
					')',
				},
			}
		)
	end

	local positionIcon
	if POSITION_ICON_DATA then
		local position = (transfer.position or ''):lower()
		positionIcon = (POSITION_ICON_DATA[position] or POSITION_ICON_DATA['']) .. '&nbsp;'
	end

	local leaveateDisplay = self:_buildLeaveDateDisplay(transfer)

	if not HAS_REFS then
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
				TeamHistoryDisplay._displayRef(transfer.reference.join, transfer.joinDateDisplay)
			},
		},
		Td{
			classes = {'th-mono'},
			css = {['white-space'] = 'nowrap', ['vertical-align'] = 'top', ['padding-left'] = '5px'},
			children = {
				leaveateDisplay,
				TeamHistoryDisplay._displayRef(transfer.reference.leave, transfer.leaveDateDisplay)
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

---@param transfer TransferSpan
---@return string?
---@return Widget
function TeamHistoryDisplay:_getTeamText(transfer)
	if Logic.isEmpty(transfer.team) and Table.includes(SPECIAL_ROLES, transfer.role) then
		return HtmlWidgets.B{children = {transfer.role}}
	elseif not TeamTemplate.exists(transfer.team) then
		return Link{link = transfer.team}
	end
	local leaveDateCleaned = TeamHistoryDisplay._adjustDate(transfer.leaveDate)
	local teamData = TeamTemplate.getRawOrNil(transfer.team, leaveDateCleaned) or {}

	return Link{
		link = teamData.page,
		children = {TeamHistoryDisplay._getTeamDisplayName(teamData)}
	}
end

---@param teamData {name: string, bracketname: string, shortname: string}
---@return string
function TeamHistoryDisplay._getTeamDisplayName(teamData)
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
function TeamHistoryDisplay._adjustDate(date)
	if Logic.isEmpty(date) then
		return date
	end
	---@cast date -nil

	local dateStruct = DateExt.parseIsoDate(date)
	dateStruct.day = dateStruct.day - 1
	return os.date('%Y-%m-%d', os.time(dateStruct)) --[[@as string]]
end

---@param transfer TransferSpan
---@return string|Widget?
function TeamHistoryDisplay:_buildLeaveDateDisplay(transfer)
	if transfer.leaveDateDisplay then return transfer.leaveDateDisplay end

	if not Table.includes(SPECIAL_ROLES, transfer.role) then
		return Span{
			css = {['font-weight'] = 'bold'},
			children = {'Present'}
		}
	end
end

---@param references table[]
---@param date string
---@return Widget?
function TeamHistoryDisplay._displayRef(references, date)
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

return TeamHistoryDisplay
