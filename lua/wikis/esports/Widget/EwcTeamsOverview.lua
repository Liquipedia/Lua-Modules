---
-- @Liquipedia
-- page=Module:Widget/EwcTeamsOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Json = Lua.import('Module:Json')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local Template = Lua.import('Module:Template')

local OverviewData = Lua.import('Module:EwcTeamsOverview/data')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local STATUSES = {
	q = {icon = 'qualified', order = 1},
	tbd = {icon = 'tobedetermined', order = 2},
	nq = {icon = 'notqualified', order = 3},
	ineligible = {icon = 'ineligible', order = 4},
}

local DEFAULT_ORDER_VALUE = 9

local function storeClubs(clubs, gameData, season)
	if Lpdb.isStorageDisabled() then
		return
	end
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

---@param props table
---@return VNode
local function EwcTeamsOverview(props)
	local season = props.season
	local gameData = OverviewData[season]
	assert(gameData, 'Invalid season: ' .. tostring(season))
	assert(props.clubs, 'No clubs provided')

	local clubs = Json.parseStringified(props.clubs)
	storeClubs(clubs, gameData, season)

	local function makeTeamCell(game, team)
		local link = game.wiki .. ':' .. team.link
		local icon = STATUSES[team.status] and STATUSES[team.status].icon or nil
		if not icon then
			return
		end
		return Link{children = Icon{iconName = icon}, link = link}
	end

	return TableWidgets.Table{
		sortable = true,
		columns = Array.extendWith(
			{
				{align = 'left'},
				{align = 'center'},
			},
			Array.rep({
				align = 'right',
				sortType = 'number',
			}, 2),
			Array.rep({align = 'center'}, #gameData)
		),
		children = {
			TableWidgets.TableHeader{
				children = WidgetUtil.collect(
					TableWidgets.CellHeader{children = 'Team Name'},
					TableWidgets.CellHeader{children = ''},
					TableWidgets.CellHeader{children = Html.Abbr{
						title = 'Qualified to X/' .. #gameData .. ' Tournaments',
						children = 'Q#',
					}},
					TableWidgets.CellHeader{children = Html.Abbr{title = 'Number of Teams', children = 'T#'}},
					Array.map(gameData, function(game)
						return TableWidgets.CellHeader{
							children = Template.expandTemplate(mw.getCurrentFrame(), 'LeagueIconSmall/' .. game.lis),
						}
					end)
				)
			},
			TableWidgets.TableBody{children = Array.map(clubs, function(club)
				return TableWidgets.Row{
					children = WidgetUtil.collect(
						TableWidgets.Cell{
							children = OpponentDisplay.InlineTeamContainer{template = club.name},
						},
						TableWidgets.Cell{
							children = club.club and Template.safeExpand(mw.getCurrentFrame(), 'LeagueIconSmall/ewc') or nil
						},
						TableWidgets.Cell{
							attributes = {
								['data-sort-value'] = club.qualified or 0
							},
							children = (club.qualified or 0) .. '/' .. #gameData
						},
						TableWidgets.Cell{children = club.teams},
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

							return TableWidgets.Cell{
								classes = {background},
								attributes = {['data-sort-value'] = sortValue or DEFAULT_ORDER_VALUE},
								children = content
							}
						end)
					)
				}
			end)}
		}
	}
end

return Component.component(EwcTeamsOverview)
