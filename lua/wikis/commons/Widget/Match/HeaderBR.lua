---
-- @Liquipedia
-- page=Module:Widget/Match/HeaderBR
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Trophy = Lua.import('Module:Widget/Match/Summary/Ffa/Trophy')
local Div = HtmlWidgets.Div

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

---@class MatchHeaderBRProps
---@field match MatchGroupUtilMatch
---@field teamStyle? teamStyle

---@class MatchHeaderBR: Widget
---@operator call(MatchHeaderBRProps): MatchHeaderBR
---@field props MatchHeaderBRProps
local MatchHeaderBR = Class.new(Widget)
MatchHeaderBR.defaultProps = {
	teamStyle = 'short',
}

---@return Widget?
function MatchHeaderBR:render()
	local match = self.props.match
	if not match then
		return nil
	end

	if #match.opponents <= 2 or not match.finished then
		return
	end

	local sortedOpponents = Array.sortBy(
		match.opponents,
		function(opponent)
			return opponent.placement
		end
	)

	local topThree = Array.sub(sortedOpponents, 1, 3)
	local placements = {'1st', '2nd', '3rd'}

	local positionRows = Array.map(topThree, function(opponent, i)
		return Div {
			classes = { 'match-info-headerbr-positionrow' },
			children = {
				Div {
					classes = { 'match-info-headerbr-positionholder' },
					children = {
						Trophy { place = i, additionalClasses = { 'panel-table__cell-icon' } },
						placements[i]
					}
				},
				Div {
					classes = { 'match-info-headerbr-opponent' },
					children = {
						OpponentDisplay.BlockOpponent {
							opponent = opponent,
							teamStyle = self.props.teamStyle,
							overflow = 'ellipsis',
							flip = true,
						}
					}
				}
			}
		}
	end)

	return Div {
		classes = { 'match-info-headerbr' },
		children = positionRows
	}
end

return MatchHeaderBR
