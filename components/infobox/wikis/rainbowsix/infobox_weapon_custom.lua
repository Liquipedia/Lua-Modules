--[[Infobox Weapon Custom]]--
local Weapon = require('Module:Infobox/Weapon')
local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Builder = require('Module:Infobox/Widget/Builder')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')
local PageLink = require('Module:Page')
local Array = require('Module:Array')
local OperatorIcon = require('Module:OperatorIcon')

local CustomWeapon = Class.new()
local CustomInjector = Class.new(Injector)

local _SIZE_OPERATOR = '25x25px'

local _weapon
local _args

function CustomWeapon.run(frame)
	local weapon = Weapon(frame)
	_weapon = weapon
	_args = _weapon.args
	weapon.createWidgetInjector = CustomWeapon.createWidgetInjector
	return weapon:createInfobox(frame)
end

function CustomWeapon:createWidgetInjector()
	return CustomInjector()
end

--[[function CustomInjector:parse(id, widgets)
	if id == 'user' then
		table.insert(widgets,
			Builder{
				builder = function()
					local operatorIcons = Array.map(Weapon:getAllArgsForBase(_args, 'user'),
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
	end
	return widgets
end]]--

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
	mw.logObject(_args)
	return widgets
end

return CustomWeapon
