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
---@field filterGroupPrefix string? has to match the `filterGroupPrefix` of the filter buttons controlling this ticker

local defaultProps = {
	upcomingDays = 5,
	completedDays = 5,
}

---@param props TournamentsTickerWidgetProps
---@return VNode
local function TournamentsTickerWidget(props)
	local data = TickerData.get(props)
	local displayGameIcons = Logic.readBool(props.displayGameIcons)

	---@param title string
	---@param tournaments StandardTournament[]
	---@return VNode
	local function buildSublist(title, tournaments)
		return Sublist{
			title = title,
			tournaments = tournaments,
			displayGameIcons = displayGameIcons,
			filterGroupPrefix = props.filterGroupPrefix,
		}
	end

	local fallbackElement = Html.Div{
		attributes = {
			['data-filter-hideable-group-fallback'] = '',
		},
		children = {
			Html.Div{
				css = {
					['margin'] = '1.5rem 0',
					['font-style'] = 'italic',
					['text-align'] = 'center',
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
					buildSublist('Upcoming', data.upcoming),
					buildSublist('Ongoing', data.ongoing),
					buildSublist('Completed', data.completed),
					fallbackElement
				}
			}
		},
	}
end

return Component.component(TournamentsTickerWidget, defaultProps)
