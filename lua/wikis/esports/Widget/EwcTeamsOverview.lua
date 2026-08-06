---
-- @Liquipedia
-- page=Module:Widget/EwcTeamsOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Json = Lua.import('Module:Json')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local Template = Lua.import('Module:Template')

local OverviewData = Lua.import('Module:EwcTeamsOverview/data')

local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class EwcTeamsOverview: Widget
---@operator call(table): EwcTeamsOverview
local EwcTeamsOverview = Class.new(Widget)

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
	local gameData = OverviewData[season]
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
			Html.Tr{
				children = WidgetUtil.collect(
					Html.Th{children = 'Team Name'},
					Html.Th{children = ''},
					Html.Th{children = Html.Abbr{title = 'Qualified to X/25 Tournaments', children = 'Q#'}},
					Html.Th{children = Html.Abbr{title = 'Number of Teams', children = 'T#'}},
					Array.map(gameData, function(game)
						return Html.Th{
							children = Template.expandTemplate(mw.getCurrentFrame(), 'LeagueIconSmall/' .. game.lis),
						}
					end)
				)
			},
			Array.map(clubs, function(club)
				return Html.Tr{
					children = WidgetUtil.collect(
						Html.Td{
							children = OpponentDisplay.InlineTeamContainer{template = club.name},
							css = {['text-align'] = 'left', ['text-wrap'] = 'nowrap'}
						},
						Html.Td{children = club.club and Template.safeExpand(mw.getCurrentFrame(), 'LeagueIconSmall/ewc') or nil},
						Html.Td{children = (club.qualified or 0) .. '/' .. #gameData},
						Html.Td{children = club.teams},
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

							return Html.Td{
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
