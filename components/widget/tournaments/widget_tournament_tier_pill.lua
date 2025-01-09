---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Tournament/Pill
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Tier = require('Module:Tier/Utils')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class TournamentsTickerWidget: Widget
---@operator call(table): TournamentsTickerWidget

local TournamentsTickerWidget = Class.new(Widget)

local COLOR_CLASSES = {
	[1] = 'tier1',
	[2] = 'tier2',
	[3] = 'tier3',
	[4] = 'tier4',
	[5] = 'tier5',
	['qualifier'] = 'qualifier',
	['monthly'] = 'monthly',
	['weekly'] = 'weekly',
	['showmatch'] = 'showmatch',
	['misc'] = 'misc',
	[-1] = 'misc',
	['school'] = 'misc',
	['default'] = 'misc', -- Fallback for when there's no match
}

---@return Widget?
function TournamentsTickerWidget:render()
	if not self.props.tournament then
		return
	end
	local tier, tierType = Tier.parseFromQueryData(self.props.tournament)
	tier, tierType = Logic.nilIfEmpty(tier), Logic.nilIfEmpty(tierType)
	if not tier then
		return
	end

	local tierShort, tierTypeShort = Tier.toShortName(tier, tierType)

	local tierNode, tierTypeNode, colorClass
	if tierTypeShort then
		local tierTypeIdentifier = Tier.toIdentifier(tierType)
		colorClass = COLOR_CLASSES[tierTypeIdentifier]
		tierNode = HtmlWidgets.Div{
			classes = {'tournament-badge__chip', 'chip--' .. COLOR_CLASSES[tier]},
			children = tierShort,
		}
		tierTypeNode = HtmlWidgets.Div{
			classes = {'tournament-badge__text'},
			children = tierTypeShort,
		}
	else
		colorClass = COLOR_CLASSES[tier]
		tierNode = HtmlWidgets.Div{
			classes = {'tournament-badge__text'},
			children = Tier.toName(tier),
		}
	end

	colorClass = colorClass or COLOR_CLASSES.default

	return HtmlWidgets.Div{
		classes = {'tournament-badge', 'badge--' .. colorClass},
		children = {tierNode, tierTypeNode},
	}
end

return TournamentsTickerWidget
