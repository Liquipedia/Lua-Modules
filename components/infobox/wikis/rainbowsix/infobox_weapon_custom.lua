---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Cell = require('Module:Infobox/Widget/Cell')
local Lua = require('Module:Lua')
local OperatorIcon = require('Module:OperatorIcon')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Weapon = require('Module:Infobox/Weapon', {requireDevIfEnabled = true})

---@class RainbowsixWeaponInfobox: WeaponInfobox
local CustomWeapon = Class.new(Weapon)
local CustomInjector = Class.new(Injector)

local _SIZE_OPERATOR = '25x25px'

---@param frame Frame
---@return Html
function CustomWeapon.run(frame)
	local weapon = CustomWeapon(frame)

	weapon:setWidgetInjector(CustomInjector(patch))
	return weapon:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'custom' then
		return {
			Cell{name = 'Operators', content = self.caller:_getOperators()},
		}
	end
	return widgets
end

---@return string[]
function CustomWeapon:_getOperators()
	local foundArgs = self:getAllArgsForBase(self.args, 'operator')

	local operatorIcons = Array.map(self:getAllArgsForBase(self.args, 'operator'), function(operator, _)
		return OperatorIcon.getImage{operator, size = _SIZE_OPERATOR}
	end)

	return table.concat(operatorIcons, '&nbsp;')
end

---@param lpdbData table
---@param args table
---@return table
function CustomWeapon:addToLpdb(lpdbData, args)
	lpdbData.extradata = Table.merge(lpdbData.extradata, {
		desc = args.desc,
		class = args.class,
		damage = args.damage,
		magsize = args.magsize,
		ammocap = args.ammocap,
		reloadspeed = args.reloadspeed,
		rateoffire = args.rateoffire,
		firemode = table.concat(self:getAllArgsForBase(args, 'firemode'), ';'),
		operators = table.concat(self:getAllArgsForBase(args, 'operator'), ';'),
		games = table.concat(self:getAllArgsForBase(args, 'game'), ';'),
	})
	return lpdbData
end

return CustomWeapon
