---
-- @Liquipedia
-- page=Module:Widget/EwcTeamsOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Json = require('Module:Json')
local Page = require('Module:Page')
local Template = require('Module:Template')

local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class EwcTeamsOverview: Widget
---@operator call(table): EwcTeamsOverview
local EwcTeamsOverview = Class.new(Widget)

local GAMES = {
	EWC2025 = {
		{lis = 'hok', wiki = 'honorofkings'},
		{lis = 'codbo6', wiki = 'callofduty'},
		{lis = 'codwz', wiki = 'callofduty'},
		{lis = 'ff', wiki = 'freefire'},
		{lis = 'sf6', wiki = 'fighters'},
		{lis = 'dota2', wiki = 'dota2'},
		{lis = 'r6s', wiki = 'rainbowsix'},
		{lis = 'cs2', wiki = 'counterstrike'},
		{lis = 'pubgm', wiki = 'pubgmobile'},
		{lis = 'apex', wiki = 'apexlegends'},
		{lis = 'fc25', wiki = 'easportsfc'},
		{lis = 'ow2', wiki = 'overwatch'},
		{lis = 'mlbb', wiki = 'mobilelegends'},
		{lis = 'mwi', wiki = 'mobilelegends'},
		{lis = 'rl', wiki = 'rocketleague'},
		{lis = 'chess', wiki = 'chess'},
		{lis = 'rennsport', wiki = 'simracing'},
		{lis = 'pubg', wiki = 'pubg'},
		{lis = 'cf', wiki = 'crossfire'},
		{lis = 'ffcotw', wiki = 'fighters'},
		{lis = 'lol', wiki = 'leagueoflegends'},
		{lis = 'tft', wiki = 'tft'},
		{lis = 'valorant', wiki = 'valorant'},
		{lis = 't8', wiki = 'fighters'},
		{lis = 'sc2', wiki = 'starcraft2'},
	}
}

local STATUSES = {
	q = {icon = 'qualified', order = 1},
	tbd = {icon = 'tobedetermined', order = 2},
	nq = {icon = 'notqualified', order = 3},
	ineligible = {icon = 'ineligible', order = 4},
}

local DEFAULT_ORDER_VALUE = 9

local function storeClubs(clubs, gameData, season)
	Array.forEach(clubs, function(club)
		if not club.name or not club.teams then return end

		local teams = Array.flatMap(gameData, function(game)
			local teams = club[game.lis]
			if not teams or type(teams) ~= 'table' then return end
			return Array.map(teams, function(team)
				return {
					pagename = Page.pageifyLink(team.link),
					status = team.status,
					wiki = game.wiki,
				}
			end)
		end)

		mw.ext.LiquipediaDB.lpdb_datapoint(mw.title.getCurrentTitle().text .. '_' .. club.name, {
			type = 'EWC_CLUB_TEAM',
			name = club.name,
			information = season,
			extradata = Json.stringify({
				teams = teams,
				supported = Logic.readBool(club.club),
			}, {asArray = true})
		})
	end)

end

---@return Widget
function EwcTeamsOverview:render()
	local season = self.props.season
	local gameData = GAMES[season]
	assert(gameData, 'Invalid season: ' .. tostring(season))
	assert(self.props.clubs, 'No clubs provided')

	local clubs = Json.parseStringified(self.props.clubs)
	storeClubs(clubs, gameData, season)

	local function makeTeamCell(game, team)
		local link = game.wiki .. ':' .. team.link
		local icon = STATUSES[team.status] and STATUSES[team.status].icon or nil
		if not icon then
			return
		end
		return Link{children = Icon{iconName = icon}, link = link}
	end

	return DataTable{
		sortable = true,
		tableCss = {
			['text-align'] = 'center',
			['font-size'] = '16px',
		},
		children = WidgetUtil.collect(
			HtmlWidgets.Tr{
				children = WidgetUtil.collect(
					HtmlWidgets.Th{children = 'Team Name'},
					HtmlWidgets.Th{children = ''},
					HtmlWidgets.Th{children = HtmlWidgets.Abbr{title = 'Qualified to X/25 Tournaments', children = 'Q#'}},
					HtmlWidgets.Th{children = HtmlWidgets.Abbr{title = 'Number of Teams', children = 'T#'}},
					Array.map(gameData, function(game)
						return HtmlWidgets.Th{
							children = Template.expandTemplate(mw.getCurrentFrame(), 'LeagueIconSmall/' .. game.lis),
						}
					end)
				)
			},
			Array.map(clubs, function(club)
				return HtmlWidgets.Tr{
					children = WidgetUtil.collect(
						HtmlWidgets.Td{
							children = mw.ext.TeamTemplate.team(club.name),
							css = {['text-align'] = 'left', ['text-wrap'] = 'nowrap'}
						},
						HtmlWidgets.Td{children = club.club and Template.safeExpand(mw.getCurrentFrame(), 'LeagueIconSmall/ewc') or nil},
						HtmlWidgets.Td{children = (club.qualified or 0) .. '/' .. #gameData},
						HtmlWidgets.Td{children = club.teams},
						Array.map(gameData, function(game)
							local background, sortValue, content
							local orgInGame = club[game.lis]

							if orgInGame and type(orgInGame) == 'table' then
								background = Array.any(orgInGame, function(team)
									return team.status ~= nil
								end) and 'forest-green-bg' or nil
								sortValue = Array.min(Array.map(orgInGame, function (item)
									return (STATUSES[item.status] or {}).order
								end))
								content = Array.interleave(Array.map(orgInGame, function(team)
									return makeTeamCell(game, team)
								end), '&nbsp;')
							end

							return HtmlWidgets.Td{
								classes = {background},
								attributes = {['data-sort-value'] = sortValue or DEFAULT_ORDER_VALUE},
								children = content
							}
						end)
					)
				}
			end)
		)
	}
end

return EwcTeamsOverview
