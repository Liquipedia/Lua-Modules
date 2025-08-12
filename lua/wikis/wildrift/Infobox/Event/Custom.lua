---
-- @Liquipedia
-- page=Module:Infobox/Event/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Event = Lua.import('Module:Infobox/Event')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class WildriftEventInfobox: InfoboxEvent
local CustomEvent = Class.new(Event)
---@class WildriftEventInfoboxInjector
---@field caller WildriftEventInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomEvent.run(frame)
	local event = CustomEvent(frame)
	event:setWidgetInjector(CustomInjector(event))

	return event:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local rewards = caller:getAllArgsForBase(args, 'reward')
		rewards = Array.interleave(rewards, HtmlWidgets.Br{})
		return WidgetUtil.collect(
			Cell{name = 'Description', content = {args.description}},
			Cell{name = 'No. of missions', content = {args.missions}},
			Logic.isNotEmpty(rewards) and Title{children = {'Rewards'}} or nil,
			Logic.isNotEmpty(rewards) and Center{children = rewards} or nil
		)
	end

	return widgets
end

return CustomEvent
