---
-- @Liquipedia
-- page=Module:Widget/MainPage/ThisDay/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Ordinal = Lua.import('Module:Ordinal')
local String = Lua.import('Module:StringUtils')

local Info = Lua.import('Module:Info', { loadData = true })

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Small = Html.Small
local WidgetUtil = Lua.import('Module:Widget/Util')

local defaultProps = {
	name = Info.name
}

---@param props {name: string?}
---@return Renderable[]
local function ThisDayTitle(props)
	local name = props.name
	assert(String.isNotEmpty(name), 'Invalid name: ' .. tostring(name))
	---@cast name -nil
	return WidgetUtil.collect(
		'This day in ' .. name .. ' ',
		Small{
			attributes = { id = 'this-day-date' },
			css = { ['margin-left'] = '5px' },
			children = { '(' .. os.date('%B') .. ' ' .. Ordinal.toOrdinal(tonumber(os.date('%d'))) .. ')' }
		}
	)
end

return Component.component(ThisDayTitle, defaultProps)
