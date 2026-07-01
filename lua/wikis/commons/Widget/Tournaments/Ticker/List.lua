---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local I18n = Lua.import('Module:I18n')

local Component = Lua.import('Module:Widget/Component')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')
local Html = Lua.import('Module:Widget/Html')
local ListItem = Lua.import('Module:Widget/Tournaments/Ticker/ListItem')
local PhaseCollapsible = Lua.import('Module:Widget/Tournaments/Ticker/PhaseCollapsible')
local Sublist = Lua.import('Module:Widget/Tournaments/Ticker/Sublist')
local TickerData = Lua.import('Module:TournamentsTicker/Data')

---@class TournamentsTickerListWidgetProps: TournamentsTickerDataProps
---@field variant 'tabs'|'collapsible'?
---@field displayGameIcons boolean?
---@field tierColorScheme string?

local defaultProps = {
	upcomingDays = 5,
	completedDays = 5,
	variant = 'tabs',
}

---@param props TournamentsTickerListWidgetProps
---@return VNode
local function TournamentsTickerList(props)
	local data = TickerData.get(props)
	local displayGameIcons = props.displayGameIcons

	---@param tournament StandardTournament
	---@return VNode
	local function createItem(tournament)
		return ListItem{
			tournament = tournament,
			displayGameIcon = displayGameIcons,
			tierColorScheme = props.tierColorScheme,
		}
	end

	---@param tournaments StandardTournament[]
	---@return VNode
	local function buildSublist(tournaments)
		return Sublist{
			tournaments = tournaments,
			createItem = createItem,
			fallback = Html.Div{
				attributes = {
					['data-filter-hideable-group-fallback'] = '',
					['data-filter-effect'] = 'fade',
				},
				children = Html.Center{
					css = {margin = '1.5rem 0', ['font-style'] = 'italic'},
					children = I18n.translate('tournament-ticker-no-tournaments'),
				},
			},
		}
	end

	local tabsWidget = ContentSwitch{
		css = { margin = '0 0.75rem 0.75rem'},
		switchGroup = 'tournament-list-phase',
		defaultActive = 2,
		storeValue = false,
		tabs = {
			{label = 'Upcoming', value = 'upcoming', content = buildSublist(data.upcoming)},
			{label = 'Ongoing', value = 'ongoing', content = buildSublist(data.ongoing)},
			{label = 'Completed', value = 'completed', content = buildSublist(data.completed)},
		},
	}

	local listContainer
	if props.variant == 'collapsible' then
		listContainer = {
			Html.Div{
				classes = {'tournaments-list--tabs'},
				children = tabsWidget,
			},
			Html.Div{
				classes = {'tournaments-list--collapsible'},
				children = {
					PhaseCollapsible{label = 'Ongoing', children = buildSublist(data.ongoing)},
					PhaseCollapsible{label = 'Upcoming', children = buildSublist(data.upcoming)},
					PhaseCollapsible{label = 'Completed', collapsed = true, children = buildSublist(data.completed)},
				},
			},
		}
	else
		listContainer = tabsWidget
	end

	return Html.Div{
		css = {['padding-top'] = '0.75rem'},
		children = listContainer,
	}
end

return Component.component(TournamentsTickerList, defaultProps)
