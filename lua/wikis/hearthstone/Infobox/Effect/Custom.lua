---
-- @Liquipedia
-- page=Module:Infobox/Effect/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Effect = Lua.import('Module:Infobox/Effect')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Title = Widgets.Title
local Cell = Widgets.Cell

---@class HearthstoneEffectInfobox: EffectInfobox
local CustomEffect = Class.new(Effect)
---@class HearthstoneEffectInfoboxInjector: WidgetInjector
---@field caller HearthstoneEffectInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomEffect.run(frame)
	local effect = CustomEffect(frame)
	effect:setWidgetInjector(CustomInjector(effect))

	return effect:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		return {
			Title{children = 'Hero Power Information'},
			Cell{name = 'Class', children = {args.class}, options = {makeLink = true}},
			Cell{name = 'Hero', children = {args.hero}, options = {makeLink = true}},
			Cell{name = 'Playable', children = {args.playable}},
		}
	end

	return widgets
end

return CustomEffect
