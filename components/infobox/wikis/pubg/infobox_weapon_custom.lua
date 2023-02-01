---
-- @Liquipedia
-- wiki=pubg
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Weapon = Lua.import('Module:Infobox/Weapon', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomWeapon = Class.new()
local CustomInjector = Class.new(Injector)

local _weapon
local _args

function CustomWeapon.run(frame)
	local weapon = Weapon(frame)
	_weapon = weapon
	_args = _weapon.args
	weapon.createWidgetInjector = CustomWeapon.createWidgetInjector
	return weapon:createInfobox()
end

function CustomWeapon:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Ammo Type',
		content = {args.ammotype}
	})
	table.insert(widgets, Cell{
		name = 'Throw Speed',
		content = {args.throwspeed}
	})
	table.insert(widgets, Cell{
		name = 'Throw Cooldown',
		content = {args.throwcooldown}
	})
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
	return widgets
end

function CustomWeapon:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomWeapon
