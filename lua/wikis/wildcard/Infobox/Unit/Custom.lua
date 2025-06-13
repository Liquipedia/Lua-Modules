---
-- @Liquipedia
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class WildcardUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))
	unit.args.informationType = 'Summon'
	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		return Array.append(widgets,
			Cell{name = 'Pronouns', content = {args.pronouns}},
			Cell{name = 'House', content = {args.house}},
			Cell{name = 'Rarity', content = {args.rarity}},
			Cell{name = 'Quantity', content = {args.quantity}},
			Cell{name = 'Mana Cost', content = {args.cost}},
			Cell{name = 'Health', content = {args.health}},
			Cell{name = 'Movement Speed', content = {args.movement}},
			Cell{name = 'Sight Range', content = {args.sightrange}},
			Cell{name = 'Key Words', content = {args.keywords}},
			Title{children = 'Basic Stats'},
			Cell{name = 'Healing', content = {args.healing}},
			Cell{name = 'Mobility', content = {args.mobility}},
			Cell{name = 'Offense', content = {args.offense}},
			Cell{name = 'Defense', content = {args.defense}},
			Cell{name = 'Utility', content = {args.utility}}
		)
	end
	return widgets
end

---@param args table
function CustomUnit:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('unit_' .. self.pagename, Json.stringifySubTables({
		name = args.name,
		type = args.informationType,
		extradata = {house = args.house or ''},
	}))
end

return CustomUnit
