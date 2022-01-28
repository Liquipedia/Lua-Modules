---
-- @Liquipedia
-- wiki=pubg
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Weapon = require('Module:Infobox/Weapon')
local Class = require('Module:Class')
local String = require('Module:String')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local CustomWeapon = Class.new()
local CustomInjector = Class.new(Injector)

local _weapon

function CustomWeapon.run(frame)
	local weapon = Weapon(frame)
	_weapon = weapon
	_args = _weapon.args
	weapon.createWidgetInjector = CustomWeapon.createWidgetInjector
	weapon.addToLpdb = CustomWeapon.addToLpdb
	return weapon:createInfobox(frame)
end

function CustomWeapon:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Ammo Type',
		content = {args.ammo_type}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	local args = _args
	
	if id == 'custom' then
		if String.isNotEmpty(args.map1) then
			local maps = {}
			
			for _, map in ipairs(_weapon:getAllArgsForBase(args, 'map')) do
				table.insert(maps, tostring(CustomWeapon:_createNoWrappingSpan(
							PageLink.makeInternalLink({}, map)
						)))
			end
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	end
	return widgets
end

function CustomWeapon:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(_league:getAllArgsForBase(args, 'map'), ';')

	lpdbData.extradata = {
		ammotype = args.ammo_type,
	}

	return lpdbData
end

function CustomWeapon:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomWeapon
