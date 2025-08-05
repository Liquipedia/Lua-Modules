---
-- @Liquipedia
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center
local WidgetImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Injector = Lua.import('Module:Widget/Injector')
local Weapon = Lua.import('Module:Infobox/Weapon')

---@class CounterstrikeWeaponInfobox: WeaponInfobox
local CustomWeapon = Class.new(Weapon)
---@class CounterstrikeWeaponInfoboxInjector
---@field caller CounterstrikeWeaponInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomWeapon.run(frame)
	local weapon = CustomWeapon(frame)
	weapon:setWidgetInjector(CustomInjector(weapon))

	return weapon:createInfobox(frame)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		return WidgetUtil.collect(
			widgets,
			Cell{name = 'Recoil control', content = {args['recoil control']}},
			Cell{name = 'Accurate range', content = {args['accurate range'] and (args['accurate range'] .. 'm') or nil}},
			Cell{name = 'Penetration power', content = {args['penetration power']}},
			Cell{name = 'Reload time', content = {args['reload time'] and (args['reload time'] .. 's') or nil}},
			Cell{name = 'Units per second', content = {args['units per second']}},
			Cell{name = 'Hotkey', content = {args.hotkey}},
			caller:_achievementsDisplay()
		)
	end

	return widgets
end

---@return Widget[]?
function CustomWeapon:_achievementsDisplay()
	local args = self.args
	local achievements = Array.mapIndexes(function(index)
		local prefix = 'achievement'  .. index
		if (not args[prefix]) or (not args[prefix .. 'image']) then return end
		return WidgetImage{
			imageLight = args[prefix .. 'image'],
			link = args[prefix .. 'link'] or '',
			size = '35px',
		}
	end)

	if Logic.isEmpty(achievements) then return end

	return {
		Title{children = {'Achievements'}},
		Center{classes = {'infobox-icons'}, children = achievements},
	}
end

return CustomWeapon
