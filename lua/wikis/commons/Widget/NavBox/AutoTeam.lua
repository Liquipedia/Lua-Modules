---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/NavBox/AutoTeam
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Info = Lua.import('Module:Info', {loadData = true})
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
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
		return member.type == 'player' and member.isMain
	end)
	local secondaryRosterActivePlayers = Logic.nilIfEmpty(Array.filter(activeMembers, function(member)
		return member.type == 'player' and not member.isMain
	end))
	local activeStaff = Array.filter(activeMembers, function(member)
		return member.type == 'staff'
	end)

	local makeNote = function(position, role)
		local content = {position, role}
		return table.concat(Array.filter(content, Logic.isNotEmpty), ' - ')
	end

	local makePersonDisplay = function(member)
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

	local orgChild = #activeStaff > 0 and Table.merge({
		name = 'Organization',
	}, Array.map(activeStaff, makePersonDisplay)) or nil

	local linkConfig = Table.merge(DEFAULT_LINK_CONFIG, Info.config.teamSubPages)

	---@param subPage string
	---@param displayText string
	---@return Widget?
	local makeLink = function(subPage, displayText)
		if not linkConfig[subPage] then return end
		return Link{link = team.pageName .. '/' .. linkConfig[subPage], children = displayText}
	end

	---@type table
	local linksChild = Array.append({Link{link = team.pageName, children = 'Overview'}},
		makeLink('results', 'Results'),
		makeLink('playedMatches', 'Played Matches'),
		makeLink('playerResults', 'Player Results')
	)
	linksChild.name = 'Team'

	return NavBox{
		image = team.image,
		imagedark = team.imageDark,
		imagelink = team.pageName,
		title = team.fullName or team.bracketName or team.shortName or team.pageName,
		child1 = linksChild,
		child2 = Table.merge({
			name = secondaryRosterActivePlayers and 'Main Roster' or 'Roster',
		}, Array.map(activePlayers, makePersonDisplay)),
		child3 = secondaryRosterActivePlayers and Table.merge({
			name = 'Additional Rosters',
		}, Array.map(secondaryRosterActivePlayers, makePersonDisplay)) or orgChild,
		child4 = secondaryRosterActivePlayers and orgChild,
	}
end

return AutoTeamNavbox
