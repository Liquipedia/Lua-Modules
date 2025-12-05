---
-- @Liquipedia
-- page=Module:Widget/Match/Page/PartyDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local SeriesDots = Lua.import('Module:Widget/Match/Page/SeriesDots')

---@class MatchPagePartyDisplayParameters
---@field opponent MatchPageOpponent
---@field flip boolean?

---@class MatchPagePartyDisplay: Widget
---@operator call(MatchPagePartyDisplayParameters): MatchPagePartyDisplay
---@field props MatchPagePartyDisplayParameters
local MatchPagePartyDisplay = Class.new(Widget)

---@return Widget?
function MatchPagePartyDisplay:render()
	return Div{
		classes = { 'match-bm-match-header-party' },
		children = self:_buildChildren()
	}
end

---@private
---@return Widget?
function MatchPagePartyDisplay:_buildChildren()
	local opponent = self.props.opponent
	if Opponent.isEmpty(opponent) then
		return
	end
	return Div{
		classes = { 'match-bm-match-header-party-group' },
		children = {
			Div{
				classes = { 'match-bm-match-header-party-group-container' },
				children = Array.map(opponent.players, function (player)
					return PlayerDisplay.BlockPlayer{player = player, flip = self.props.flip}
				end)
			},
			SeriesDots{seriesDots = opponent.seriesDots},
		}
	}
end

return MatchPagePartyDisplay
