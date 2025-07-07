---
-- @Liquipedia
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Variables = Lua.import('Module:Variables')
local VersionDisplay = Lua.import('Infobox/Extension/VersionDisplay')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Weapon = Lua.import('Module:Infobox/Weapon')

local Widgets = Lua.import('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class FortniteWeaponInfobox: WeaponInfobox
local CustomWeapon = Class.new(Weapon)
---@class FortniteWeaponInfoboxInjector
---@field caller FortniteWeaponInfobox
local CustomInjector = Class.new(Injector)

local HARVESTING_TOOL = 'Harvesting Tool'

---@param frame Frame
---@return Html
function CustomWeapon.run(frame)
	local weapon = CustomWeapon(frame)
	local args = weapon.args
	args.informationType = args.informationType or args.type == HARVESTING_TOOL and 'Tools' or nil
	if Logic.readBool(args['generate description']) then
		weapon:_createDescription()
	end

	weapon:setWidgetInjector(CustomInjector(weapon))

	return weapon:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args
	if id == 'released' then
		return {
			Cell{name = 'Type', content = {args.type}, options = {makeLink = true}},
			Cell{name = 'Released', content = {VersionDisplay.run(args.release)}},
			Cell{name = 'Removed', children = {VersionDisplay.run(args.removed)}},
			Cell{name = 'Rarity', children = caller:getAllArgsForBase(args, 'rarity'), options = {makeLink = true}},
		}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomWeapon:getWikiCategories(args)
	local weaponType = args.type == HARVESTING_TOOL and HARVESTING_TOOL or 'Weapons'
	local wikiCategories = Array.map(self:getAllArgsForBase(self.args, 'rarity'), function(rarity)
		return rarity .. ' ' .. weaponType
	end)
	return Array.append(wikiCategories, {
		args.type and (args.type .. 's') or nil
	})
end

---@private
function CustomWeapon:_createDescription()
	local rarities = self:getAllArgsForBase(self.args, 'rarity')
	local weaponType = self.args.type == HARVESTING_TOOL and HARVESTING_TOOL or 'Weapons'
	local description = '<b>' .. self.name .. '</b> is a ' .. weaponType .. ' that is available in  '
		.. mw.text.listToText(rarities, ', ', ' and ')
		.. ' ' .. (#rarities > 1 and 'rarities' or 'rarity') .. '.'

	Variables.varDefine('description', description)
end

return CustomWeapon
