---
-- @Liquipedia
-- page=Module:Widget/Tournament/TierPill
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Tier = Lua.import('Module:Tier/Utils')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class TournamentsTickerPillWidgetProps
---@field tournament StandardTournament
---@field variant 'solid'|'subtle'?
---@field colorScheme 'full'|'top3'?

---@class TournamentsTickerPillWidget: Widget
---@operator call(TournamentsTickerPillWidgetProps): TournamentsTickerPillWidget
---@field props TournamentsTickerPillWidgetProps
local TournamentsTickerPillWidget = Class.new(Widget)

TournamentsTickerPillWidget.defaultProps = {
	variant = 'solid',
	colorScheme = 'full',
}

local COLOR_CLASSES = {
	[1] = 'tier1',
	[2] = 'tier2',
	[3] = 'tier3',
	[4] = 'tier4',
	[5] = 'tier5',
	['qualifier'] = 'qualifier',
	['monthly'] = 'monthly',
	['weekly'] = 'weekly',
	['biweekly'] = 'weekly',
	['daily'] = 'weekly',
	['showmatch'] = 'showmatch',
	['misc'] = 'misc',
	[-1] = 'misc',
	['default'] = 'misc', -- Fallback for when there's no match
}

---@return Widget?
function TournamentsTickerPillWidget:render()
	local tournament = self.props.tournament
	if not tournament then
		return
	end

	local subtle = self.props.variant == 'subtle'
	local tierShort, tierTypeShort = Tier.toShortName(tournament.liquipediaTier, tournament.liquipediaTierType)

	local colorClass
	if tierTypeShort and not subtle then
		colorClass = COLOR_CLASSES[tournament.liquipediaTierType]
	else
		colorClass = COLOR_CLASSES[tournament.liquipediaTier]
	end
	colorClass = colorClass or COLOR_CLASSES.default

	local chipText = subtle and Tier.toName(tournament.liquipediaTier) or tierShort
	local textContent = tierTypeShort and tierTypeShort or Tier.toName(tournament.liquipediaTier)

	return HtmlWidgets.Div{
		classes = WidgetUtil.collect(
			'tournament-badge',
			'badge--' .. colorClass,
			subtle and 'tournament-badge--subtle' or nil,
			self.props.colorScheme == 'top3' and 'tournament-badge--top3' or nil
		),
		children = WidgetUtil.collect(
			tierTypeShort and HtmlWidgets.Div{
				classes = WidgetUtil.collect(
					'tournament-badge__chip',
					not subtle and 'chip--' .. COLOR_CLASSES[tournament.liquipediaTier] or nil
				),
				children = chipText,
			} or nil,
			HtmlWidgets.Div{
				classes = {'tournament-badge__text'},
				children = textContent,
			}
		),
	}
end

return TournamentsTickerPillWidget
