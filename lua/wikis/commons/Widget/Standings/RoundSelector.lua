---
-- @Liquipedia
-- page=Module:Widget/Standings/RoundSelector
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local HtmlWidgets = Lua.import('Module:Widget/Html')
local Button = Lua.import('Module:Widget/Basic/Button')

---@private
---@return string
local function finalRoundTitle(hasEnded, rounds)
	if not hasEnded then
		return 'Current'
	else
		return 'Round ' .. tostring(rounds)
	end
end

---@param props {rounds: integer?, hasEnded: boolean?}
---@return Renderable?
local function RoundSelectorWidget(props)
	if not props.rounds or props.rounds <= 1 then
		return
	end

	local roundTitles = Array.map(Array.range(1, props.rounds), function (round)
		if round == props.rounds then
			return finalRoundTitle(props.hasEnded, props.rounds)
		else
			return 'Round ' .. round
		end
	end)

	local function makeRoundButtons(roundTitle, roundIndex)
		return Button{
			children = roundTitle,
			variant = 'primary',
			size = 'sm',
			classes = {'toggle-area-button'},
			attributes = {['data-toggle-area-btn'] = roundIndex},
		}
	end

	return HtmlWidgets.Div{
		classes = {'dropdown-box-wrapper'},
		css = {float = 'left'},
		children = {
			Button{
				children = finalRoundTitle(props.hasEnded, props.rounds),
				variant = 'primary',
				size = 'sm',
				classes = {'dropdown-box-button'},
			},
			HtmlWidgets.Div{
				classes = {'dropdown-box'},
				css = {padding = '0px'},
				children = Array.map(roundTitles, makeRoundButtons)
			},
		}
	}
end

return Component.component(RoundSelectorWidget)
