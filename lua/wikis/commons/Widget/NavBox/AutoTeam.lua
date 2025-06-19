---
-- @Liquipedia
-- page=Module:Widget/NavBox/AutoTeam
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Array = Lua.import('Module:Array')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

local TeamService = Lua.import('Module:Service/Team')

local NavBox = Lua.import('Module:Widget/NavBox')

local DEFAULT_LINK_CONFIG = {
	results = 'Results',
	playedMatches = 'Played Matches',
}

---@class AutoTeamNavbox: Widget
---@operator call(table): AutoTeamNavbox
local AutoTeamNavbox = Class.new(Widget)
AutoTeamNavbox.defaultProps = {team = mw.title.getCurrentTitle().prefixedText}

---@return Widget?
function AutoTeamNavbox:render()
	local team = TeamService.getTeamByTemplate(self.props.team)
	if not team then
		return
	end

	local members = team.members

	if not members or #members == 0 then
		return
	end

	local activeMembers = Array.filter(members, function(member)
		return member.status == 'active' and Logic.isNotEmpty(member.displayName)
	end)

	local activePlayers = Array.filter(activeMembers, function(member)
		return member.type == 'player'
	end)
	local activePlayersByGroup = Array.groupBy(activePlayers, Operator.property('group'))

	local activeStaff = Array.filter(activeMembers, function(member)
		return member.type == 'staff'
	end)
	local config = Info.config.teamRosterNavbox or {}
	local showOrg = not config.hideOrg

	local childrenArray = WidgetUtil.collect(
		{AutoTeamNavbox._makeLinksChild(team.pageName)},
		Array.map(activePlayersByGroup, function(playerGroup)
			local name = #activePlayersByGroup == 1 and 'Roster' or (String.upperCaseFirst(playerGroup[1].group) .. ' Roster')
			return AutoTeamNavbox._makeRosterRow(playerGroup, name)
		end),
		showOrg and (AutoTeamNavbox._makeRosterRow(activeStaff, 'Organization')) or nil
	)

	local children = Table.map(childrenArray, function(index, child) return 'child' .. index, child end)

	return NavBox(Table.merge(children, {
		image = team.image,
		imagedark = team.imageDark,
		imagelink = team.pageName,
		imagesize = '50px',
		title = (team.fullName or team.bracketName or team.shortName or team.pageName) .. ' Roster',
	}))
end

---@param pageName string
---@return table?
function AutoTeamNavbox._makeLinksChild(pageName)
	local config = Info.config.teamRosterNavbox or {}
	if config.hideOverview then return end

	local linkConfig = Table.merge(DEFAULT_LINK_CONFIG, config.links)

	---@param subPage string
	---@param displayText string
	---@return Widget?
	local makeLink = function(subPage, displayText)
		if not linkConfig[subPage] then return end
		return Link{link = pageName .. '/' .. linkConfig[subPage], children = displayText}
	end

	---@type table
	local linksChild = Array.append({Link{link = pageName, children = 'Overview'}},
		makeLink('results', 'Results'),
		not config.hidePlayedMatches and makeLink('playedMatches', 'Played Matches') or nil,
		makeLink('playerResults', 'Player Results')
	)
	linksChild.name = 'Team'

	return linksChild
end

---@param members table[]?
---@param name string
---@return table?
function AutoTeamNavbox._makeRosterRow(members, name)
	if Logic.isEmpty(members) then return end
	---@cast members -nil
	---@type table
	local rosterRow = Array.map(members, AutoTeamNavbox._makePersonDisplay)
	rosterRow.name = name
	return rosterRow
end

---@param member table
---@return Widget
function AutoTeamNavbox._makePersonDisplay(member)
	local makeNote = function(position, role)
		local content = {position, role}
		return table.concat(Array.filter(content, Logic.isNotEmpty), ' - ')
	end

	local note = Logic.nilIfEmpty(makeNote(member.position, member.role))
	return HtmlWidgets.Fragment{children = {
		Link{
			link = member.pageName,
			children = member.displayName,
		},
		note and '&nbsp;' or nil,
		note and HtmlWidgets.Small{children = HtmlWidgets.I{children = '(' .. note .. ')'}} or nil,
	}}
end

return AutoTeamNavbox
