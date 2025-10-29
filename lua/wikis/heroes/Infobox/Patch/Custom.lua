---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Patch = Lua.import('Module:Infobox/Patch')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class HeroesPatchInfobox: PatchInfobox
local CustomPatch = Class.new(Patch)

---@class HeroesPatchInfoboxWidgetInjector: WidgetInjector
---@field caller HeroesPatchInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local customPatch = CustomPatch(frame)
	customPatch:setWidgetInjector(CustomInjector(customPatch))
	return customPatch:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args  = caller.args
	if id == 'release' then
		table.insert(widgets, Cell{name = 'NA Release Date', children = {args.narelease}})
	end

	return widgets
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	---@param input string?
	---@return string?
	local prefixIfExists = function(input)
		return input and ('Patch ' .. input) or nil
	end
	return {previous = prefixIfExists(args.previous), next = prefixIfExists(args.next)}
end

return CustomPatch
