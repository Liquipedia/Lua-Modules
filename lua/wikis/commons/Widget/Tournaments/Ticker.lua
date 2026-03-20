---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local I18n = Lua.import('Module:I18n')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Sublist = Lua.import('Module:Widget/Tournaments/Ticker/Sublist')
local TickerData = Lua.import('Module:Widget/Tournaments/Ticker/Data')

---@class TournamentsTickerWidget: Widget
---@operator call(table): TournamentsTickerWidget
local TournamentsTickerWidget = Class.new(Widget)
TournamentsTickerWidget.defaultProps = {
	upcomingDays = 5,
	completedDays = 5,
}

---@return Widget
function TournamentsTickerWidget:render()
	local data = TickerData.get(self.props)
	local displayGameIcons = Logic.readBool(self.props.displayGameIcons)

	local fallbackElement = HtmlWidgets.Div{
		attributes = {
			['data-filter-hideable-group-fallback'] = '',
		},
		children = {
			HtmlWidgets.Center{
				css = {
					['margin'] = '1.5rem 0',
					['font-style'] = 'italic',
				},
				children = I18n.translate('tournament-ticker-no-tournaments'),
			}
		}
	}

	return HtmlWidgets.Div{
		children = {
			HtmlWidgets.Ul{
				classes = {'tournaments-list'},
				attributes = {
					['data-filter-hideable-group'] = '',
					['data-filter-effect'] = 'fade',
				},
				children = {
					Sublist{title = 'Upcoming', tournaments = data.upcoming, displayGameIcons = displayGameIcons},
					Sublist{title = 'Ongoing', tournaments = data.ongoing, displayGameIcons = displayGameIcons},
					Sublist{title = 'Completed', tournaments = data.completed, displayGameIcons = displayGameIcons},
					fallbackElement
				}
			}
		},
	}
end

return TournamentsTickerWidget
