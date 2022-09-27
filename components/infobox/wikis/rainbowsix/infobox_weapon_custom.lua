---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Weapon = require('Module:Infobox/Weapon')
local Class = require('Module:Class')
local Builder = require('Module:Infobox/Widget/Builder')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Array = require('Module:Array')
local OperatorIcon = require('Module:OperatorIcon')
local Table = require('Module:Table')

local CustomWeapon = Class.new()
local CustomInjector = Class.new(Injector)

local _SIZE_OPERATOR = '25x25px'

local _weapon
local _args

function CustomWeapon.run(frame)
	local weapon = Weapon(frame)
	_weapon = weapon
	_args = _weapon.args

	weapon.addToLpdb = CustomWeapon.addToLpdb
	weapon.createWidgetInjector = CustomWeapon.createWidgetInjector
	return weapon:createInfobox(frame)
end

function CustomWeapon:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	-- Operators
	table.insert(widgets,
		Builder{
			builder = function()
				local operatorIcons = Array.map(Weapon:getAllArgsForBase(_args, 'operator'),
					function(operator, _)
						return OperatorIcon.getImage{operator, size = _SIZE_OPERATOR}
					end
				)
				return {
					Cell{
						name = #operatorIcons > 1 and 'Operators' or 'Operator',
						content = {
							table.concat(operatorIcons, '&nbsp;')
						}
					}
				}
			end
		})
	return widgets
end

function CustomWeapon:addToLpdb(lpdbData, args)
	lpdbData.extradata = Table.merge(lpdbData.extradata, {
		desc = args.desc,
		class = args.class,
		damage = args.damage,
		magsize = args.magsize,
		ammocap = args.ammocap,
		reloadspeed = args.reloadspeed,
		rateoffire = args.rateoffire,
		firemode = table.concat(_weapon:getAllArgsForBase(args, 'firemode'), ';'),
		operators = table.concat(_weapon:getAllArgsForBase(args, 'operator'), ';'),
		games = table.concat(_weapon:getAllArgsForBase(args, 'game'), ';'),
	})
	return lpdbData
end

return CustomWeapon
