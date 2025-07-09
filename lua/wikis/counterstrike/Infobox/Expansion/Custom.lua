---
-- @Liquipedia
-- page=Module:Infobox/Expansion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')

local Expansion = Lua.import('Module:Infobox/Expansion')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

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
	local caller  = self.caller
	local args  = caller.args
	if id == 'custom' then
		local maps = caller:getMaps()
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

---@return (Widget|string)[]
function CustomExpansion:getMaps()
	local mapInput = Json.parseIfTable(self.args.maps) or {}
	local maps = Array.mapIndexes(function(mapIndex)
		local prefix = 'map' .. mapIndex
		local map = mapInput[prefix]
		local mapMode = mapInput[prefix .. 'mode'] == 'cs' and {mode = 'Hostage', abbr = '(H)'}
			or {mode = 'Defuse', abbr = '(D)'}
		if not map then return end
		return HtmlWidgets.Fragment{children = {
			Link{link = map},
			' ',
			mapInput[prefix .. 'mode'] == 'cs' and HtmlWidgets.Abbr{title = 'Hostage', children = {'(H)'}}
				or HtmlWidgets.Abbr{title = 'Defuse', children = {'(D)'}},
		}}
	end)

	return Array.interleave(maps, ', ')
end

return CustomExpansion
