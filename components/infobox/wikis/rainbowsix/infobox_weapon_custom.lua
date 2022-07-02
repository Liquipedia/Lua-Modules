---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Weapon = require('Module:Infobox/Weapon')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Array = require('Module:Array')
local OperatorIcon = require('Module:OperatorIcon')

local CustomWeapon = Class.new()
local CustomInjector = Class.new(Injector)

local _SIZE_OPERATOR = '25x25px'

local _args

function CustomWeapon.run(frame)
	local weapon = Weapon(frame)
	_args = weapon.args
	weapon.createWidgetInjector = CustomWeapon.createWidgetInjector
	return weapon:createInfobox(frame)
end

function CustomWeapon:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	-- Operators
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

return CustomWeapon
