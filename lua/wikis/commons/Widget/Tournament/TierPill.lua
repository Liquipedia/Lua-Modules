---
-- @Liquipedia
-- page=Module:Widget/Tournament/TierPill
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Tier = Lua.import('Module:Tier/Utils')

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

	local tierShort, tierTypeShort = Tier.toShortName(tournament.liquipediaTier, tournament.liquipediaTierType)

	local colorClass
	if tierTypeShort then
		colorClass = COLOR_CLASSES[tournament.liquipediaTierType]
	else
		colorClass = COLOR_CLASSES[tournament.liquipediaTier]
	end
	colorClass = colorClass or COLOR_CLASSES.default

	if self.props.variant == 'subtle' then
		local subtleColorClass
		local children
		if tierTypeShort then
			subtleColorClass = COLOR_CLASSES[tournament.liquipediaTier] or COLOR_CLASSES.default
			children = {
				HtmlWidgets.Div{
					classes = {'tournament-badge__chip'},
					children = Tier.toName(tournament.liquipediaTier),
				},
				HtmlWidgets.Div{
					classes = {'tournament-badge__text'},
					children = tierTypeShort,
				},
			}
		else
			subtleColorClass = colorClass
			children = {
				HtmlWidgets.Div{
					classes = {'tournament-badge__text'},
					children = Tier.toName(tournament.liquipediaTier),
				}
			}
		end
		local classes = {'tournament-badge', 'tournament-badge--subtle', 'badge--' .. subtleColorClass}
		if self.props.colorScheme == 'top3' then
			table.insert(classes, 3, 'tournament-badge--top3')
		end
		return HtmlWidgets.Div{
			classes = classes,
			children = children,
		}
	end

	local tierNode, tierTypeNode
	if tierTypeShort then
		tierNode = HtmlWidgets.Div{
			classes = {'tournament-badge__chip', 'chip--' .. COLOR_CLASSES[tournament.liquipediaTier]},
			children = tierShort,
		}
		tierTypeNode = HtmlWidgets.Div{
			classes = {'tournament-badge__text'},
			children = tierTypeShort,
		}
	else
		tierNode = HtmlWidgets.Div{
			classes = {'tournament-badge__text'},
			children = Tier.toName(tournament.liquipediaTier),
		}
	end

	return HtmlWidgets.Div{
		classes = {'tournament-badge', 'badge--' .. colorClass},
		children = {tierNode, tierTypeNode},
	}
end

return TournamentsTickerPillWidget
