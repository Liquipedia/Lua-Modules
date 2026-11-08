---
-- @Liquipedia
-- page=Module:Features/QualificationChances/Components/ChanceBar
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Array = Lua.import('Module:Array')
local Component = Lua.import('Module:Widget/Component')

local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

local TONES_BY_STAGE_COUNT = {
	{44},
	{20, 80},
	{20, 44, 80},
	{20, 30, 44, 80},
	{10, 20, 30, 44, 80},
}
local NOT_QUALIFIED_COLOR = 'var(--clr-secondary-90)'

---@param index integer
---@param count integer
---@return string
local function stageColor(index, count)
	local tones = TONES_BY_STAGE_COUNT[count] or TONES_BY_STAGE_COUNT[#TONES_BY_STAGE_COUNT]
	return 'var(--clr-primary-' .. tones[(index - 1) % #tones + 1] .. ')'
end

---@param props {color: string, share: number}
---@return Renderable?
local function Segment(props)
	if props.share <= 0 then
		return
	end
	return Html.Div{
		classes = {'qualification-chances-bar__segment'},
		css = {['flex-grow'] = props.share, ['background-color'] = props.color},
	}
end

---@param props {chance: number, stages: number[]}
---@return Renderable
local function QualificationChanceBar(props)
	local stages = props.stages
	return Html.Div{
		classes = {'qualification-chances-bar'},
		children = WidgetUtil.collect(
			#stages == 0 and Segment{color = stageColor(1, 1), share = props.chance} or nil,
			Array.map(stages, function(chance, stageIndex)
				return Segment{color = stageColor(stageIndex, #stages), share = chance}
			end),
			Segment{color = NOT_QUALIFIED_COLOR, share = 1 - props.chance}
		),
	}
end

return Component.component(QualificationChanceBar)
