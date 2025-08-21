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

	if #match.opponents < 3 then
		return
	end

	local sortedOpponents = Array.sortBy(
		match.opponents,
		function(opponent)
			return opponent.placement
		end
	)

	local first = sortedOpponents[1]
	local second = sortedOpponents[2]
	local third = sortedOpponents[3]

	return Div {
		classes = { 'match-info-headerbr' },
		children = {
			Div {
				classes = { 'match-info-headerbr-positionrow' },
				children = {
					Div {
						classes = { 'match-info-headerbr-positionholder' },
						children = {
							Trophy{place = 1},
							'1st'
						}

					},
					Div {
						classes = { 'match-info-headerbr-opponent' },
						children = {
							OpponentDisplay.BlockOpponent {
								opponent = first,
								teamStyle = self.props.teamStyle,
								overflow = 'ellipsis',
								flip = true,
							}
						}
					}
				}
			},
			Div {
				classes = { 'match-info-header-positionrow' },
				children = {
					Div {
						classes = { 'match-info-header-positionholder' },
						children = {
							Trophy{place = 2},
							'2nd'
						}

					},
					Div {
						classes = { 'match-info-headerbr-opponent' },
						children = {
							OpponentDisplay.BlockOpponent {
								opponent = second,
								teamStyle = self.props.teamStyle,
								overflow = 'ellipsis',
								flip = true,
							}
						}
					}
				}
			},
			Div {
				classes = { 'match-info-header-positionrow' },
				children = {
					Div {
						classes = { 'match-info-header-positionholder' },
						children = {
							Trophy{place = 3},
							'3rd'
						}

					},
					Div {
						classes = { 'match-info-headerbr-opponent' },
						children = {
							OpponentDisplay.BlockOpponent {
								opponent = third,
								teamStyle = self.props.teamStyle,
								overflow = 'ellipsis',
								flip = true,
							}
						}
					}
				}
			},
		}
	}
end

return MatchHeaderBR
