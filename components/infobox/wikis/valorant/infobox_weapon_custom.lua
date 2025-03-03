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
local Builder = Widgets.Builder
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
local FIRE_RATE_UNIT = 'rounds/sec'

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
	-- args['fire rate'] should be botted to args.rateoffire
	args.rateoffire = args['fire rate']
	-- args['fire rate min'] should be botted to args.minrateoffire
	args.minrateoffire = args['fire rate min']
	-- args['fire rate max'] should be botted to args.maxrateoffire
	args.maxrateoffire = args['fire rate max']
	-- args['alternate fire rate'] should be botted to args.altrateoffire
	args.altrateoffire = args['alternate fire rate']
	-- args['movement speed'] should be botted to args.movementspeed
	args.movementspeed = args['movement speed']
	-- args['wall penetration'] should be botted to args.wallpenetration
	args.wallpenetration = args['wall penetration']

	args.disableClassLink = true
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
			args.price and Cell{
				name = 'Price',
				options = { separator = ' ' },
				content = { CREDS_ICON, args.price }
			} or nil
		}
	elseif id == 'damage' then
		return {
			Builder{
				builder = function()
					return {
						Cell{
							name = 'Damage',
							content = self.caller:getAllArgsForBase(args, 'damage'),
						}
					}
				end
			}
		}
	elseif id == 'killaward' then
		return {
			args.killaward and Cell{
				name = 'Kill Award',
				options = { separator = ' ' },
				content = { CREDS_ICON, args.killaward }
			} or nil
		}
	elseif id == 'rateoffire' then
		local rateOfFire = Logic.emptyOr(
			args.rateoffire,
			(args.minrateoffire or '?') .. '-' .. (args.maxrateoffire or '?')
		)
		return {
			Cell{
				name = 'Fire rate',
				options = { separator = ' ' },
				content = { rateOfFire, FIRE_RATE_UNIT }
			},
			Cell{
				name = 'Alternate Fire rate',
				options = { separator = ' ' },
				content = {
					args.altrateoffire,
					args.altrateoffire and FIRE_RATE_UNIT or nil
				}
			}
		}
	end
	if id == 'custom' then
		return WidgetUtil.collect(
			Cell{
				name = 'Wall peneration',
				content = { args.wallpenetration }
			},
			Cell{
				name = 'Movement speed',
				content = { args.movementspeed .. ' m/sec' }
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
		wallpenetration = args.wallpenetration,
		ammo = args.ammo,
		capacity = args.capacity,
		reload = args.reloadspeed,
		movementspeed = args.movementspeed,
		firingmode = args.firemode,
		firerate = args.rateoffire,
		fireratemin = args.minrateoffire,
		fireratemax = args.maxrateoffire,
		fireratealternate = args.altrateoffire,
	}
	return lpdbData
end

return CustomWeapon
