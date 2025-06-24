---
-- @Liquipedia
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Weapon = Lua.import('Module:Infobox/Weapon')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Link = Lua.import('Module:Widget/Basic/Link')

---@class PubgmobileWeaponInfobox: WeaponInfobox
local CustomWeapon = Class.new(Weapon)
---@class PubgmobileWeaponInfoboxInjector
---@field caller PubgmobileWeaponInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomWeapon.run(frame)
	local weapon = CustomWeapon(frame)
	weapon:setWidgetInjector(CustomInjector(weapon))

	return weapon:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args
	if id == 'custom' then
		return {
			Cell{name = 'Type', children = {
				args.type and Link{
					link = ':Category:' .. args.type .. 's',
					children = {args.type .. 's'},
				} or nil
			}},
			Cell{name = 'Ammo Type', children = {args.ammotype}, options = {makeLink = true}},
			Cell{name = 'Reload time', children = {args['reload time']}},
			Cell{name = 'Throw time', children = {args['throw time'] and (args['throw time'] .. 's') or nil}},
			Cell{name = 'Throw cooldown', children = {args['throw time'] and (args['throw cooldown'] .. 's') or nil}},
			Cell{name = 'Released', children = {args.release}},
			Cell{name = 'Removed', children = {args.removed}},
			Cell{name = 'Maps', children = caller:getAllArgsForBase(args, 'map', {makeLink = true})}
		}
	elseif id == 'damage' then
		return {
			Cell{name = 'Damage', children = {args.damage}},
			Cell{name = 'Base Damage', children = {args['base damage']}},
			Cell{name = 'Area Damage', children = {args['area damage']}},
		}
	elseif id == 'magsize' then
		return {
			Cell{name = 'Magazine Size', options = {separator = ' '}, children = {
				args.damage,
				args['ext-magazine'] and ('(Extended: ' .. args['ext-magazine'] .. ')') or nil,
			}},
		}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomWeapon:getWikiCategories(args)
	local maps = self:getAllArgsForBase(args, 'map')
	local categories = Array.map(maps, function(map)
		return map .. ' Weapons'
	end)
	return Array.append(categories,
		args.ammotype and (args.ammotype .. ' Gun') or nil
	)
end

return CustomWeapon
