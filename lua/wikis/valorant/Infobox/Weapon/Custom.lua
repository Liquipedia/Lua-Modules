---
-- @Liquipedia
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local AutoInlineIcon = Lua.import('Module:AutoInlineIcon')
local Injector = Lua.import('Module:Widget/Injector')
local Weapon = Lua.import('Module:Infobox/Weapon')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local WidgetUtil = Lua.import('Module:Widget/Util')

local CREDS_ICON = AutoInlineIcon.display{onlyicon = true, category = 'M', lookup = 'creds'}
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
			Cell{
				name = 'Damage',
				content = self.caller:getAllArgsForBase(args, 'damage'),
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
		local rateOfFire = args.rateoffire
		local minRateOfFire = args.minrateoffire
		local maxRateOfFire = args.maxrateoffire
		local altRateOfFire = Logic.isNotEmpty(rateOfFire) and not (
			Logic.isEmpty(minRateOfFire) and Logic.isEmpty(maxRateOfFire)
		)
		if altRateOfFire then
			rateOfFire = (minRateOfFire or '?') .. '-' .. (maxRateOfFire or '?')
		end
		return rateOfFire and {
			Cell{
				name = 'Firerate',
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
		} or {}
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
		wallpenetration = args.wallpenetration,
		magsize = args.magsize,
		ammocap = args.ammocap,
		reload = args.reloadspeed,
		movementspeed = args.movementspeed,
		firemode = args.firemode,
		rateoffire = args.rateoffire,
		minrateoffire = args.minrateoffire,
		maxrateoffire = args.maxrateoffire,
		altrateoffire = args.altrateoffire,
	}
	return lpdbData
end

return CustomWeapon
