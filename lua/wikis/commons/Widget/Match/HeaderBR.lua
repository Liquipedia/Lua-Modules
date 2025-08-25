---
-- @Liquipedia
-- page=Module:Widget/Match/HeaderBR
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Operator = Lua.import('Module:Operator')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Trophy = Lua.import('Module:Widget/Match/Summary/Ffa/Trophy')
local Div = HtmlWidgets.Div

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Placement = Lua.import('Module:Placement')

---@class MatchHeaderBRProps
---@field match FFAMatchGroupUtilMatch
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

	local topThree = Array.filter(
		Array.sortBy(match.opponents, Operator.property('placement')),
		function(opponent) return opponent.placement <= 3 end
	)

	local positionRows = Array.map(topThree, function(opponent, i)
		return Div {
			classes = { 'match-info-headerbr-positionrow' },
			children = {
				Div {
					classes = { 'match-info-headerbr-positionholder' },
					children = {
						Trophy { place = i },
						Placement._makeOrdinal({i})[1]
					}
				},
				Div {
					classes = { 'match-info-headerbr-opponent' },
					children = {
						OpponentDisplay.BlockOpponent {
							opponent = opponent,
							teamStyle = self.props.teamStyle,
							overflow = 'ellipsis',
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
