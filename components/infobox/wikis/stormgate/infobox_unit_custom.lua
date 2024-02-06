---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Attack = require('Module:Infobox/Extension/Attack')
local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Hotkeys = require('Module:Hotkey')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class Stormgate2UnitInfobox: UnitInfobox
---@field faction string?
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=]]'
local ICON_ENERGY = '[[File:EnergyIcon.gif|link=]]'

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))

	unit.faction = Faction.read(unit.args.faction)
	unit.args.informationType = unit.args.informationType or 'Unit'

	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'type' then

	end

	return widgets
end

---@param args table
---@return string
function CustomUnit:nameDisplay(args)
	local factionIcon = Faction.Icon{size = 'large', faction = self.faction or Faction.defaultFaction}
	factionIcon = factionIcon and (factionIcon .. '&nbsp;') or ''

	return factionIcon .. (args.name or self.pagename)
end

---@return string?
function CustomUnit:_getHotkeys()
	local display
	if not String.isEmpty(self.args.hotkey) then
		if not String.isEmpty(self.args.hotkey2) then
			display = Hotkeys.hotkey2(self.args.hotkey, self.args.hotkey2, 'arrow')
		else
			display = Hotkeys.hotkey(self.args.hotkey)
		end
	end

	return display
end

---@param args table
function CustomUnit:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('unit_' .. self.pagename, {
		name = args.name,
		type = args.informationType,
		information = self.faction,
		image = args.image,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			here
		},
	})
end


---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	local unitType = args.informationType .. 's'
	local faction = Faction.toName(self.faction)
	local categories = {unitType}

	if not faction then
		return categories
	end

	return Array.append(categories,
		faction .. unitType
	)
end

---@param hotkey1 string?
---@param hotkey2 string?
---@return string?
function CustomUnit._hotkeys(hotkey1, hotkey2)
	if String.isEmpty(hotkey1) then return end
	if String.isEmpty(hotkey2) then
		return Hotkeys.hotkey(hotkey1)
	end
	return Hotkeys.hotkey2(hotkey1, hotkey2, 'plus')
end

---@param inputString string?
---@param makeLink boolean?
---@return string[]
function CustomUnit:_readCommaSeparatedList(inputString, makeLink)
	if String.isEmpty(inputString) then return {} end
	---@cast inputString -nil
	local values = Array.map(mw.text.split(inputString, ','), String.trim)
	if not makeLink then return values end
	return Array.map(values, Page.makeInternalLink)
end

return CustomUnit
