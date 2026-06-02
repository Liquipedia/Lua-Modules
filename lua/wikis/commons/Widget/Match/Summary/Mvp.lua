---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Mvp
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local Div, Span, Fragment = Html.Div, Html.Span, Html.Fragment
local Link = Lua.import('Module:Widget/Basic/Link')

---@param props {players: MatchGroupMvpPlayer[]?, points: integer?}
---@return VNode?
local function MatchSummaryMVP(props)
	if props.players == nil or #props.players == 0 then
		return nil
	end
	local points = tonumber(props.points)
	local players = Array.map(props.players, function(inputPlayer)
		local player = type(inputPlayer) ~= 'table' and {name = inputPlayer, displayname = inputPlayer} or inputPlayer

		return Fragment{children = {
			Link{link = player.name, children = player.displayname},
			player.comment and ' (' .. player.comment .. ')' or nil
		}}
	end)
	return Div{
		classes = {'brkts-popup-footer', 'brkts-popup-mvp'},
		children = Span{
			children = WidgetUtil.collect(
				#players > 1 and 'MVPs: ' or 'MVP: ',
				Array.interleave(players, ', '),
				points and points > 1 and ' (' .. points .. ' pts)' or nil
			),
		},
	}
end

return Component.component(MatchSummaryMVP)
