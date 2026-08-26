---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local I18n = Lua.import('Module:I18n')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Sublist = Lua.import('Module:Widget/Tournaments/Ticker/Sublist')
local TickerData = Lua.import('Module:TournamentsTicker/Data')

---@class TournamentsTickerWidgetProps: TournamentsTickerDataProps
---@field displayGameIcons boolean?

local defaultProps = {
	upcomingDays = 5,
	completedDays = 5,
}

---@param props TournamentsTickerWidgetProps
---@return VNode
local function TournamentsTickerWidget(props)
	local data = TickerData.get(props)
	local displayGameIcons = Logic.readBool(props.displayGameIcons)

	local fallbackElement = Html.Div{
		attributes = {
			['data-filter-hideable-group-fallback'] = '',
		},
		children = {
			Html.Center{
				css = {
					['margin'] = '1.5rem 0',
					['font-style'] = 'italic',
				},
				children = I18n.translate('tournament-ticker-no-tournaments'),
			}
		}
	}

	return Html.Div{
		children = {
			Html.Div{
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

return Component.component(TournamentsTickerWidget, defaultProps)
