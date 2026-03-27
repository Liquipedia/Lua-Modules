---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local I18n = Lua.import('Module:I18n')
local Widget = Lua.import('Module:Widget')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local ListItem = Lua.import('Module:Widget/Tournaments/Ticker/ListItem')
local PhaseCollapsible = Lua.import('Module:Widget/Tournaments/Ticker/PhaseCollapsible')
local Sublist = Lua.import('Module:Widget/Tournaments/Ticker/Sublist')
local TickerData = Lua.import('Module:TournamentsTicker/Data')

---@class TournamentsTickerListWidgetProps: TournamentsTickerDataProps
---@field variant 'tabs'|'collapsible'?
---@field displayGameIcons boolean?
---@field tierColorScheme string?

---@class TournamentsTickerListWidget: Widget
---@operator call(TournamentsTickerListWidgetProps): TournamentsTickerListWidget
---@field props TournamentsTickerListWidgetProps
local TournamentsTickerListWidget = Class.new(Widget)
TournamentsTickerListWidget.defaultProps = {
	upcomingDays = 5,
	completedDays = 5,
	variant = 'tabs',
}

---@return Widget
function TournamentsTickerListWidget:render()
	local data = TickerData.get(self.props)
	local displayGameIcons = self.props.displayGameIcons

	---@param tournament StandardTournament
	---@return Widget
	local function createItem(tournament)
		return ListItem{
			tournament = tournament,
			displayGameIcon = displayGameIcons,
			tierColorScheme = self.props.tierColorScheme,
		}
	end

	---@param tournaments StandardTournament[]
	---@return Widget
	local function buildSublist(tournaments)
		return Sublist{
			tournaments = tournaments,
			createItem = createItem,
			fallback = HtmlWidgets.Div{
				attributes = {
					['data-filter-hideable-group-fallback'] = '',
					['data-filter-effect'] = 'fade',
				},
				children = HtmlWidgets.Center{
					css = {margin = '1.5rem 0', ['font-style'] = 'italic'},
					children = I18n.translate('tournament-ticker-no-tournaments'),
				},
			},
		}
	end

	local tabsWidget = ContentSwitch{
		css = { margin = '0.75rem'},
		switchGroup = 'tournament-list-phase',
		defaultActive = 2,
		storeValue = false,
		tabs = {
			{label = 'Upcoming', value = 'upcoming', content = buildSublist(data.upcoming)},
			{label = 'Ongoing', value = 'ongoing', content = buildSublist(data.ongoing)},
			{label = 'Completed', value = 'completed', content = buildSublist(data.completed)},
		},
	}

	if self.props.variant ~= 'collapsible' then
		return tabsWidget
	end

	return HtmlWidgets.Div{
		children = {
			HtmlWidgets.Div{
				classes = {'tournaments-list--tabs'},
				children = tabsWidget,
			},
			HtmlWidgets.Div{
				classes = {'tournaments-list--collapsible'},
				children = {
					PhaseCollapsible{label = 'Ongoing', children = buildSublist(data.ongoing)},
					PhaseCollapsible{label = 'Upcoming', children = buildSublist(data.upcoming)},
					PhaseCollapsible{label = 'Completed', collapsed = true, children = buildSublist(data.completed)},
				},
			},
		},
	}
end

return TournamentsTickerListWidget
