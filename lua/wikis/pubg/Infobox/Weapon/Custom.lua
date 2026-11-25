---
-- @Liquipedia
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local PageLink = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Weapon = Lua.import('Module:Infobox/Weapon')

local Widgets = Lua.import('Module:Widget/Infobox/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title
local NoWrap = Widgets.NoWrap

---@class PubgWeaponInfobox: WeaponInfobox
local CustomWeapon = Class.new(Weapon)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
function CustomWeapon.run(frame)
	local weapon = CustomWeapon(frame)
	weapon:setWidgetInjector(CustomInjector(weapon))

	return weapon:createInfobox()
end

---@param id string
---@param widgets Renderable[]
---@return Renderable[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Ammo Type', children = {args.ammotype}},
			Cell{name = 'Throw Speed', children = {args.throwspeed}},
			Cell{name = 'Throw Cooldown', children = {args.throwcooldown}}
		)

		if String.isEmpty(args.map1) then
			return widgets
		end

		local maps = Array.map(self.caller:getAllArgsForBase(args, 'map'), function(map)
			return NoWrap{children = PageLink.makeInternalLink({}, map)}
		end)

		table.insert(widgets, Title{children = 'Maps'})
		table.insert(widgets, Center{children = Array.interleave(maps, '&nbsp;• ')})
	end

	return widgets
end

return CustomWeapon
