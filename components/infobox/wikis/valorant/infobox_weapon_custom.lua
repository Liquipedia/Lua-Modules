---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Weapon = Lua.import('Module:Infobox/Weapon')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')
local Span = Widgets.Span
local WidgetUtil = Lua.import('Module:Widget/Util')

local CREDS_ICON = Span{
	css = { ['white-space'] = 'nowrap'},
	children = {
		IconImageWidget{
			imageLight = 'Black_Creds_VALORANT.png',
			imageDark = 'White_Creds_VALORANT.png',
			link = 'Creds',
			size = '10px'
		}
	}
}

---@class ValorantWeaponInfobox: WeaponInfobox
local CustomWeapon = Class.new(Weapon)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomWeapon.run(frame)
	local weapon = CustomWeapon(frame)

	local args = weapon.args
	--args['firing mode'] should be botted to args.firemode
	args.firemode = args['firing mode']
	--args.ammo should be botted to args.magsize
	args.magsize = args.ammo
	--args.capacity should be botted to args.ammocap
	args.ammocap = args.capacity
	--args['reload time'] should be botted to args.reloadspeed
	args.reloadspeed = args['reload time']

	weapon:setWidgetInjector(CustomInjector(weapon))

	return weapon:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'price' then
		return {
			Cell{
				name = 'Price',
				content = { CREDS_ICON, args.price }
			}
		}
	elseif id == 'killaward' then
		return {
			Cell{
				name = 'Kill Award',
				content = { CREDS_ICON, args.killaward }
			}
		}
	elseif id == 'rateoffire' then
		return {
			Cell{
				name = 'Fire rate',
				content = {
					-- 'fire rate' should be botted to
					-- 'rateoffire' for standardization
					Logic.emptyOr(
						args['fire rate'],
						(args['fire rate min'] or '?') .. '-' .. (args['fire rate max'] or '?')
					),
					args['fire rate'] and ' rounds/sec' or nil
				}
			},
			Cell{
				name = 'Alternate Fire rate',
				content = {
					args['alternate fire rate'],
					args['alternate fire rate'] and ' rounds/sec' or nil
				}
			}
		}
	end
	if id == 'custom' then
		return WidgetUtil.collect(
			Cell{
				name = 'Wall peneration',
				content = { args['wall penetration'] }
			},
			Cell{
				name = 'Movement speed',
				content = { args['movement speed'] }
			}
		)
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomWeapon:addToLpdb(lpdbData, args)
	lpdbData.extradata = {
		class = args.class,
		price = args.price,
		damage = args.damage,
		wallpenetration = args['wall penetration'],
		ammo = args.ammo,
		capacity = args.capacity,
		reload = args['reload time'],
		movementspeed = args['movement speed'],
		firingmode = args['firing mode'],
		firerate = args['fire rate'],
		fireratemin = args['fire rate min'],
		fireratemax = args['fire rate max'],
		fireratealternate = args['alternate fire rate'],
	}
	return lpdbData
end

return CustomWeapon
