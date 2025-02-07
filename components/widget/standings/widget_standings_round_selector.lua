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
	local rounds = self.props.rounds
	local numOfRounds = #rounds
	if not rounds or numOfRounds == 0 then
		return
	end

	local function finalRoundTitle()
		if not self.props.hasEnded then
			return 'Current'
		end
	end

	local roundTitles = Array.map(rounds, function (round, roundIndex)
		return roundIndex == numOfRounds and finalRoundTitle() or round.title
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
