---
-- @Liquipedia
-- page=Module:Widget/Match/Page/PartyDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPagePartyDisplayParameters
---@field opponent MatchPageOpponent

local RESULT_DISPLAY_TYPES = {
	['w'] = 'winner',
	['l'] = 'loser',
	['winner'] = 'winner',
	['loser'] = 'loser',
	['-'] = 'notplayed'
}

---@class MatchPagePartyDisplay: Widget
---@operator call(MatchPagePartyDisplayParameters): MatchPagePartyDisplay
---@field props MatchPagePartyDisplayParameters
local MatchPagePartyDisplay = Class.new(Widget)


---@private
---@param result string
---@return Widget
function MatchPagePartyDisplay._makeGameResultIcon(result)
	return Div{
		classes = { 'match-bm-match-header-round-result', 'result--' .. RESULT_DISPLAY_TYPES[result:lower()] }
	}
end

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
					return PlayerDisplay.InlinePlayer{player = player}
				end)
			},
			Logic.isNotEmpty(opponent.seriesDots) and Div{
				classes = { 'match-bm-match-header-round-results' },
				children = Array.map(opponent.seriesDots, MatchPagePartyDisplay._makeGameResultIcon)
			} or nil,
		}
	}
end

return MatchPagePartyDisplay
