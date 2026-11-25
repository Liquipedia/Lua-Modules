---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/Mvp
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local Html = Lua.import('Module:Widget/Html')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')

---@param props {players: MatchGroupMvpPlayer[], points: integer}
---@return VNode?
local function MatchSummaryFfaMvp(props)
	if Logic.isEmpty(props.players) then
		return nil
	end
	local points = tonumber(props.points)
	local players = Array.map(props.players, function(inputPlayer)
		local player = type(inputPlayer) ~= 'table' and {name = inputPlayer, displayname = inputPlayer} or inputPlayer

		return Html.Fragment{children = {
			Link{link = player.name, children = player.displayname},
			player.comment and ' (' .. player.comment .. ')' or nil
		}}
	end)

	return ContentItemContainer{contentClass = 'panel-content__game-schedule', items = {{
		icon = IconWidget{iconName = 'mvp', color = 'bright-sun-0-text', size = '0.875rem'},
		title = 'MVP:',
		content = Html.Span{children = Array.extend(
			players,
			points and points > 1 and (' (' .. points .. ' pts)') or nil
		)},
	}}}
end

return Component.component(MatchSummaryFfaMvp)
