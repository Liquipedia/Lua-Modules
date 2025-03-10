---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Standings/RoundSelector
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Button = Lua.import('Module:Widget/Basic/Button')

---@class RoundSelectorWidget: Widget
---@operator call(table): RoundSelectorWidget

local RoundSelectorWidget = Class.new(Widget)

---@return Widget?
function RoundSelectorWidget:render()
	if not self.props.rounds or self.props.rounds <= 1 then
		return
	end

	local function finalRoundTitle()
		if not self.props.hasEnded then
			return 'Current'
		else
			return 'Round ' .. tostring(self.props.rounds)
		end
	end

	local roundTitles = Array.map(Array.range(1, self.props.rounds), function (round)
		if round == self.props.rounds then
			return finalRoundTitle()
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
				children = finalRoundTitle(),
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

return RoundSelectorWidget
