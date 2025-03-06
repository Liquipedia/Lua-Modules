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

	args.disableClassLink = true
	args.reloadspeedunit = 's'
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
				content = { args.movementspeed and (args.movementspeed .. ' m/sec') or nil }
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
		damage = self:getAllArgsForBase(args, 'damage'),
		damage2 = args.damage2,
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
