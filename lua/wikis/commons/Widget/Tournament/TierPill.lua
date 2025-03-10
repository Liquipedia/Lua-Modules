---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Tournament/TierPill
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Tier = require('Module:Tier/Utils')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class TournamentsTickerPillWidget: Widget
---@operator call(table): TournamentsTickerPillWidget

local TournamentsTickerPillWidget = Class.new(Widget)

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

	local tierShort, tierTypeShort = Tier.toShortName(tournament.liquipediaTier,tournament.liquipediaTierType)

	local tierNode, tierTypeNode, colorClass
	if tierTypeShort then
		colorClass = COLOR_CLASSES[tournament.liquipediaTierType]
		tierNode = HtmlWidgets.Div{
			classes = {'tournament-badge__chip', 'chip--' .. COLOR_CLASSES[tournament.liquipediaTier]},
			children = tierShort,
		}
		tierTypeNode = HtmlWidgets.Div{
			classes = {'tournament-badge__text'},
			children = tierTypeShort,
		}
	else
		colorClass = COLOR_CLASSES[tournament.liquipediaTier]
		tierNode = HtmlWidgets.Div{
			classes = {'tournament-badge__text'},
			children = Tier.toName(tournament.liquipediaTier),
		}
	end

	colorClass = colorClass or COLOR_CLASSES.default

	return HtmlWidgets.Div{
		classes = {'tournament-badge', 'badge--' .. colorClass},
		children = {tierNode, tierTypeNode},
	}
end

return TournamentsTickerPillWidget
