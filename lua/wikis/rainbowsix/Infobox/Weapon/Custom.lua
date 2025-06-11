---
-- @Liquipedia
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local CharacterNames = require('Module:CharacterNames')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Weapon = Lua.import('Module:Infobox/Weapon')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class RainbowsixWeaponInfobox: WeaponInfobox
local CustomWeapon = Class.new(Weapon)
local CustomInjector = Class.new(Injector)

local SIZE_OPERATOR = '25x25px'

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
	if id == 'custom' then
		return {
			Cell{name = 'Operators', content = {self.caller:_getOperators()}},
		}
	end
	return widgets
end

---@return string
function CustomWeapon:_getOperators()
	local operatorIcons = Array.map(self:getAllArgsForBase(self.args, 'operator'), function(operator)
		return CharacterIcon.Icon{character = CharacterNames[operator:lower()], size = SIZE_OPERATOR}
	end)

	return table.concat(operatorIcons, '&nbsp;')
end

---@param lpdbData table
---@param args table
---@return table
function CustomWeapon:addToLpdb(lpdbData, args)
	local operators = Array.map(self:getAllArgsForBase(self.args, 'operator'), function(operator)
		return CharacterNames[operator:lower()]
	end)
	lpdbData.extradata = Table.merge(lpdbData.extradata, {
		desc = args.desc,
		class = args.class,
		damage = args.damage,
		magsize = args.magsize,
		ammocap = args.ammocap,
		reloadspeed = args.reloadspeed,
		rateoffire = args.rateoffire,
		firemode = table.concat(self:getAllArgsForBase(args, 'firemode'), ';'),
		operators = table.concat(operators, ';'),
		games = table.concat(self:getAllArgsForBase(args, 'game'), ';'),
	})
	return lpdbData
end

return CustomWeapon
