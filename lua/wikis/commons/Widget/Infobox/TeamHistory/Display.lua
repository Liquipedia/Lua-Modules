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
	['advisor'] = {display = 'Advisor'},
	['ambassador'] = {display = 'Ambassador'},
	['assistant coach/analyst'] = {display = 'Asst. Coach&Analyst'},
	['assistant general manager'] = {display = 'Assistant General Manager', abbreviation = 'AGM.'},
	['assistant team manager'] = {display = 'Assistant Team Manager', abbreviation = 'ATM.'},
	['associate producer'] = {display = 'Associate Producer'},
	['asst. coach/manager'] = {display = 'Asst. Coach/Manager'},
	['backup'] = {display = 'Backup'},
	['ceo'] = {display = 'CEO'},
	['coach/analyst'] = {display = 'Coach/Analyst', abbreviation = 'C./A.'},
	['coach/manager'] = {display = 'Coach/Manager'},
	['coach/substitute'] = {display = 'Coach/Substitute'},
	['co-ceo'] = {display = 'CO-CEO'},
	['co-coach'] = {display = 'Co-Coach'},
	['committee'] = {display = 'Committee'},
	['community lead'] = {display = 'Community Lead'},
	['damage'] = {display = 'Damage'},
	['data science'] = {display = 'Data Scientist'},
	['director of athletics'] = {display = 'Director of Athletics'},
	['director of overwatch operations'] = {display = 'Director of Overwatch Operations', abbreviation = 'DOO'},
	['director of players'] = {display = 'Director of Players', abbreviation = 'DP'},
	['director of team operations'] = {display = 'Director of Team Operations', abbreviation = 'DTO'},
	['founder & training director'] = {display = 'Founder & Training Director', abbreviation = 'F. & TD.'},
	['founder'] = {display = 'Founder'},
	['freestyler'] = {display = 'Freestyler'},
	['front line'] = {display = 'Front Line'},
	['general manager'] = {display = 'General Manager', abbreviation = 'GM.'},
	['graphic designer'] = {display = 'Graphic Designer'},
	['guest'] = {display = 'Guest'},
	['head of competitive operations'] = {display = 'Head of Competitive Operations', abbreviation = 'HCO'},
	['head of esports'] = {display = 'Head of esports'},
	['head of gaming'] = {display = 'Head of Gaming'},
	['head of socials'] = {display = 'Head of Socials'},
	['inactive coach'] = {display = 'Inactive Coach'},
	['inactive loan'] = {display = 'Inactive Loan'},
	['inactive manager'] = {display = 'Inactive Manager'},
	['inactive'] = {display = 'Inactive', abbreviation = 'Ia.'},
	['interim coach'] = {display = 'Interim Coach'},
	['loaned assistant coach'] = {display = 'Loaned Asst. Coach'},
	['loaned coach'] = {display = 'Loaned Coach'},
	['manager and analyst'] = {display = 'Manager/Analyst', abbreviation = 'M./A.'},
	['manager/analyst'] = {display = 'Manager/Analyst', abbreviation = 'M./A.'},
	['manager/substitute'] = {display = 'Manager/Substitute'},
	['mental coach/manager'] = {display = 'Mental Coach/Manager'},
	['mental coach'] = {display = 'Mental Coach'},
	['organisation'] = {display = 'Organization', abbreviation = 'Org.'},
	['overall coach'] = {display = 'Overall Coach', abbreviation = 'OC.'},
	['pa'] = {display = 'Passed Away'},
	['performance coach'] = {display = 'Performance Coach', abbreviation = 'PC'},
	['qualifier'] = {display = 'Qualifier'},
	['rlcs stand-in'] = {display = 'RLCS Stand-in'},
	['social media coordinator'] = {display = 'Social Media Coordinator', abbreviation = 'SMC'},
	['social media manager'] = {display = 'Social Media Manager', abbreviation = 'SMM'},
	['sports director'] = {display = 'Sports Dir.'},
	['stand-in-coach'] = {display = 'Stand-in-Coach'},
	['substitute/manager'] = {display = 'Substitute/Manager'},
	['substitute'] = {display = 'Substitute', abbreviation = 'Sub.'},
	['suspended coach'] = {display = 'Suspended Coach'},
	['suspended'] = {display = 'Suspended'},
	['tactical coach'] = {display = 'Tactical Coach'},
	['talent scout'] = {display = 'Talent Scout'},
	['team leader'] = {display = 'Team Leader'},
	['team manager'] = {display = 'Team Manager', abbreviation = 'TM.'},
	['team owner'] = {display = 'Team Owner'},
	['teamless'] = {display = 'Teamless'},
	['trainee coach'] = {display = 'Trainee Coach'},
	['trainee'] = {display = 'Trainee'},
	['training advisor'] = {display = 'Training Advisor', abbreviation = 'TA.'},
	['trial analyst'] = {display = 'Trial Analyst'},
	['trial coach'] = {display = 'Trial Coach'},
	['trial loan'] = {display = 'Trial Loan'},
	['trial'] = {display = 'Trial'},
	['tryout'] = {display = 'Tryout'},
	['uncontracted coach'] = {display = 'Uncontracted Coach'},
	['uncontracted'] = {display = 'Uncontracted'},
}
NOT_YET_IN_ROLES_DATA['coach and analyst'] = NOT_YET_IN_ROLES_DATA['coach/analyst']
NOT_YET_IN_ROLES_DATA['coach & analyst'] = NOT_YET_IN_ROLES_DATA['coach/analyst']
NOT_YET_IN_ROLES_DATA.gm = NOT_YET_IN_ROLES_DATA['general manager']
NOT_YET_IN_ROLES_DATA.sub = NOT_YET_IN_ROLES_DATA.substitute
NOT_YET_IN_ROLES_DATA.org = NOT_YET_IN_ROLES_DATA.organisation
NOT_YET_IN_ROLES_DATA.organization = NOT_YET_IN_ROLES_DATA.organisation

local HAS_REFS = ((Info.config.infoboxPlayer or {}).automatedHistory or {}).hasHeaderAndRefs
local USES_ABBREVIATION = Logic.nilOr(((Info.config.infoboxPlayer or {}).automatedHistory or {}).useAbbreviations, true)

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
		elseif USES_ABBREVIATION and roleData.abbreviation then
			role = roleData and Abbr{title = roleData.display, children = {roleData.abbreviation}}
		end
	end
	---@type (string|Widget)[]
	local teamDisplay = WidgetUtil.collect(
		role == LOAN and '&#8250;&nbsp;' or nil,
		teamText
	)
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
