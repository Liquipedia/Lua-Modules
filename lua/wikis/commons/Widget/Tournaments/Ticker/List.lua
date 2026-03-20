---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local I18n = Lua.import('Module:I18n')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local ListItem = Lua.import('Module:Widget/Tournaments/Ticker/ListItem')
local TickerData = Lua.import('Module:Widget/Tournaments/Ticker/Data')
local FilterConfig = Lua.import('Module:FilterButtons/Config')

---@class TournamentsTickerListWidget: Widget
---@operator call(table): TournamentsTickerListWidget
local TournamentsTickerListWidget = Class.new(Widget)
TournamentsTickerListWidget.defaultProps = {
	upcomingDays = 5,
	completedDays = 5,
}

---@return Widget
function TournamentsTickerListWidget:render()
	local data = TickerData.get(self.props)
	local displayGameIcons = Logic.readBool(self.props.displayGameIcons)

	---@param tournament StandardTournament
	---@param child Widget
	---@return Widget
	local function createFilterWrapper(tournament, child)
		return Array.reduce(FilterConfig.categories, function(prev, filterCategory)
			local itemIsValid = filterCategory.itemIsValid or function(item) return true end
			local itemToPropertyValues = filterCategory.itemToPropertyValues or function(item) return item end
			local value = tournament[filterCategory.property]
			local filterValue = itemIsValid(value) and value or filterCategory.defaultItem
			return HtmlWidgets.Div{
				attributes = {
					['data-filter-group'] = 'filterbuttons-' .. filterCategory.name,
					['data-filter-category'] = itemToPropertyValues(filterValue),
					['data-curated'] = tournament.featured and '' or nil,
				},
				children = prev,
			}
		end, child)
	end

	---@param tournaments StandardTournament[]
	---@return Widget
	local function buildTabContent(tournaments)
		local fallback = HtmlWidgets.Div{
			attributes = {
				['data-filter-hideable-group-fallback'] = '',
				['data-filter-effect'] = 'fade',
			},
			children = HtmlWidgets.Center{
				css = {margin = '1.5rem 0', ['font-style'] = 'italic'},
				children = I18n.translate('tournament-ticker-no-tournaments'),
			},
		}

		local list = HtmlWidgets.Ul{
			classes = {'tournaments-list-type-list'},
			children = Array.map(tournaments, function(tournament)
				return HtmlWidgets.Li{
					children = createFilterWrapper(tournament, ListItem{
						tournament = tournament,
						displayGameIcon = displayGameIcons,
					})
				}
			end),
		}

		return HtmlWidgets.Div{
			attributes = {
				['data-filter-hideable-group'] = '',
				['data-filter-effect'] = 'fade',
			},
			children = {list, fallback},
		}
	end

	return ContentSwitch{
		switchGroup = 'tournament-list-phase',
		defaultActive = 2,
		storeValue = false,
		tabs = {
			{label = 'Upcoming', value = 'upcoming', content = buildTabContent(data.upcoming)},
			{label = 'Ongoing', value = 'ongoing', content = buildTabContent(data.ongoing)},
			{label = 'Completed', value = 'completed', content = buildTabContent(data.completed)},
		},
	}
end

return TournamentsTickerListWidget
