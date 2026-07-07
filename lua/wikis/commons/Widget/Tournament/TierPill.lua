---
-- @Liquipedia
-- page=Module:Widget/Tournament/TierPill
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Tier = Lua.import('Module:Tier/Utils')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class TournamentsTickerPillProps
---@field tournament StandardTournament
---@field variant 'solid'|'subtle'?
---@field colorScheme 'full'|'top3'?

local defaultProps = {
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

---@param props TournamentsTickerPillProps
---@return VNode?
local function TournamentsTickerPill(props)
	local tournament = props.tournament
	if not tournament then
		return
	end

	local subtle = props.variant == 'subtle'
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

	return Html.Div{
		classes = WidgetUtil.collect(
			'tournament-badge',
			'badge--' .. colorClass,
			subtle and 'tournament-badge--subtle' or nil,
			props.colorScheme == 'top3' and 'tournament-badge--top3' or nil
		),
		children = WidgetUtil.collect(
			tierTypeShort and Html.Div{
				classes = WidgetUtil.collect(
					'tournament-badge__chip',
					not subtle and 'chip--' .. COLOR_CLASSES[tournament.liquipediaTier] or nil
				),
				children = chipText,
			} or nil,
			Html.Div{
				classes = {'tournament-badge__text'},
				children = textContent,
			}
		),
	}
end

return Component.component(TournamentsTickerPill, defaultProps)
