---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/MapVeto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local NavigationCard = Lua.import('Module:Widget/MainPage/NavigationCard')

---@class MatchPageMapVetoParameters
---@field vetoRounds {name: string, link: string, type: 'pick'|'ban'|'decider', round: integer, by: standardOpponent}[]

---@class MatchPageMapVeto: Widget
---@operator call(MatchPageMapVetoParameters): MatchPageMapVeto
---@field props MatchPageMapVetoParameters
local MatchPageMapVeto = Class.new(Widget)

---@return Widget
function MatchPageMapVeto:render()
	local formatTitle = function(vetoRound)
		if vetoRound.type == 'pick' then
			return 'Pick ' .. vetoRound.by.name
		elseif vetoRound.type == 'ban' then
			return 'Ban ' .. vetoRound.by.name
		elseif vetoRound.type == 'decider' then
			return 'Decider'
		end
	end

	return Div{
		classes = {'navigation-cards'},
		children = Array.map(self.props.vetoRounds, function(vetoRound)
			return NavigationCard{
				file = vetoRound.name .. ' Map.png',
				link = vetoRound.link,
				title = formatTitle(vetoRound),
			}
		end)
	}
end

return MatchPageMapVeto
