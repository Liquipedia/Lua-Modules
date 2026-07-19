---
-- @Liquipedia
-- page=Module:Widget/Tournament/Label
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local DateRange = Lua.import('Module:Widget/Misc/DateRange')
local Link = Lua.import('Module:Widget/Basic/Link')
local TierPill = Lua.import('Module:Widget/Tournament/TierPill')
local Title = Lua.import('Module:Widget/Tournament/Title')

---@class TournamentsTickerLabelProps
---@field tournament StandardTournament
---@field displayGameIcon boolean?

---@param props TournamentsTickerLabelProps
---@return VNode?
local function TournamentsTickerLabel(props)
	local tournament = props.tournament
	if not tournament then
		return
	end
	return Html.Div{
		css = {
			display = 'flex',
			gap = '5px',
			['margin-top'] = '0.3em',
			['margin-left'] = '10px',
		},
		children = {
			TierPill{tournament = tournament},
			Html.Span{
				classes = {'tournaments-list-name'},
				css = {
					['padding-left'] = props.displayGameIcon and '50px' or '25px',
				},
				children = Title{
					tournament = tournament,
					displayGameIcon = props.displayGameIcon
				},
			},
			Html.Small{
				classes = {'tournaments-list-dates'},
				css = {
					['flex-shrink'] = '0',
				},
				children = Link{
					children = DateRange{startDate = tournament.startDate, endDate = tournament.endDate},
					link = tournament.pageName
				},
			},
		},
	}
end

return Component.component(TournamentsTickerLabel)
