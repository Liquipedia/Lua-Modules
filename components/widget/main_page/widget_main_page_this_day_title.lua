---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/MainPage/ThisDay/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Ordinal = require('Module:Ordinal')
local String = require('Module:StringUtils')

local Info = Lua.import('Module:Info', { loadData = true })

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Small = HtmlWidgets.Small
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ThisDayTitle: Widget
---@field props { name: string? }
---@operator call(table): ThisDayTitle
local ThisDayTitle = Class.new(Widget)
ThisDayTitle.defaultProps = {
	name = Info.name
}

function ThisDayTitle:render()
	local name = self.props.name
	assert(String.isNotEmpty(name), 'Invalid name: ' .. tostring(name))
	return WidgetUtil.collect(
		'This day in ' .. name .. ' ',
		Small{
			attributes = { id = 'this-day-date' },
			css = { ['margin-left'] = '5px' },
			children = { '(' .. os.date('%B') .. ' ' .. Ordinal.toOrdinal(tonumber(os.date('%d'))) .. ')' }
		}
	)
end

return ThisDayTitle
