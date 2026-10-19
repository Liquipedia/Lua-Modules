---
-- @Liquipedia
-- page=Module:Widget/Standings/RoundSelector
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Button = Lua.import('Module:Widget/Basic/Button')

---@private
---@param round integer
---@param titles string[]?
---@return string
local function titleOfRound(round, titles)
	return (titles or {})[round] or ('Round ' .. tostring(round))
end

---@private
---@param hasEnded boolean
---@param rounds integer
---@param titles string[]?
---@return string
local function finalRoundTitle(hasEnded, rounds, titles)
	if not hasEnded then
		return 'Current'
	else
		return titleOfRound(rounds, titles)
	end
end

---@param props {rounds: integer?, hasEnded: boolean?, titles: string[]?}
---@return Renderable?
local function RoundSelectorWidget(props)
	if not props.rounds or props.rounds <= 1 then
		return
	end

	local roundTitles = Array.mapRange(1, props.rounds, function (round)
		if round == props.rounds then
			return finalRoundTitle(props.hasEnded, props.rounds, props.titles)
		else
			return titleOfRound(round, props.titles)
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

	return Html.Div{
		classes = {'dropdown-box-wrapper'},
		css = {float = 'left'},
		children = {
			Button{
				children = finalRoundTitle(props.hasEnded, props.rounds, props.titles),
				variant = 'primary',
				size = 'sm',
				classes = {'dropdown-box-button'},
			},
			Html.Div{
				classes = {'dropdown-box'},
				css = {padding = '0px'},
				children = Array.map(roundTitles, makeRoundButtons)
			},
		}
	}
end

return Component.component(RoundSelectorWidget)
