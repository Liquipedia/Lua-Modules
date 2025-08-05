---
-- @Liquipedia
-- page=Module:Infobox/Unit/Car/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class RocketLeagueUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))
	unit.args.informationType = 'Car'
	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		return {
			Cell{name = 'Released', content = {args.released}},
		}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	if Namespace.isMain() then
		return {'Cars'}
	end

	return {}
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		name = args.name or self.pagename,
		type = 'car',
		image = args.image,
		date = args.released,
		-- extradata gets set via a template further down on the page
	}

	-- Wikicode was: car_{{#explode:{{PAGENAME}}|/|1}}
	local splitPagename = mw.text.split(self.pagename, '/')
	-- wiki code explode is 0 indexed, lua is 1 indexed, hence use 2 if present
	local objectName = 'car_' .. (splitPagename[2] or splitPagename[1])

	mw.ext.LiquipediaDB.lpdb_datapoint(objectName, lpdbData)
end

return CustomUnit
