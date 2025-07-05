---
-- @Liquipedia
-- page=Module:Infobox/Expansion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Expansion = Lua.import('Module:Infobox/Expansion')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class CounterstrikeExpansionInfobox: ExpansionInfobox
local CustomExpansion = Class.new(Expansion)

---@class CounterstrikeExpansionInfoboxWidgetInjector: WidgetInjector
---@field caller CounterstrikeExpansionInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomExpansion.run(frame)
	local expansion = CustomExpansion(frame)
	expansion:setWidgetInjector(CustomInjector(expansion))
	return expansion:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args  = self.caller.args
	if id == 'custom' then
		-- hack around mw butchering the display (factually the next 2 lines are a non op)
		local maps = Array.parseCommaSeparatedString(args.maps)
		maps = Array.interleave(maps, ', ')
		return Array.append({},
			Cell{name = 'Case', children = {args.case}},
			Cell{name = 'Campaigns', children = {args.campaigns}},
			Cell{name = 'Source', children = {args.source}},
			args.collections and Title{children = {'Collections'}} or nil,
			Center{children = {args.collections}},
			Logic.isNotEmpty(maps) and Title{children = {'Maps'}} or nil,
			Center{children = maps}
		)
	elseif id == 'type' then
		return {}
	end

	return widgets
end

return CustomExpansion
