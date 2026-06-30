---
-- @Liquipedia
-- page=Module:Widget/Match/Header/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Operator = Lua.import('Module:Operator')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html/All')
local Trophy = Lua.import('Module:Widget/Match/Summary/Ffa/Trophy')
local Div = Html.Div

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Placement = Lua.import('Module:Placement')

---@class MatchHeaderFfaProps
---@field match FFAMatchGroupUtilMatch
---@field teamStyle? teamStyle

local defaultProps = {
	teamStyle = 'short',
}

---@param props MatchHeaderFfaProps
---@return VNode?
local function MatchHeaderFfa(props)
	local match = props.match
	if not match then
		return nil
	end

	if #match.opponents <= 2 or not match.finished then
		return
	end

	local topThree = Array.sub(
		Array.sortBy(
			Array.filter(
				match.opponents,
				Operator.property('placement')
			),
			Operator.property('placement')
		),
		1, 3
	)

	local positionRows = Array.map(topThree, function(opponent, i)
		return Div {
			classes = { 'match-info-headerbr-positionrow' },
			children = {
				Div {
					classes = { 'match-info-headerbr-positionholder' },
					children = {
						Trophy{ place = i },
						Placement._makeOrdinal({ i })[1]
					}
				},
				Div {
					classes = { 'match-info-headerbr-opponent' },
					children = {
						OpponentDisplay.BlockOpponent {
							opponent = opponent,
							teamStyle = props.teamStyle,
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

return Component.component(MatchHeaderFfa, defaultProps)
