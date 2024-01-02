---
-- @Liquipedia
-- wiki=pubg
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Weapon = Lua.import('Module:Infobox/Weapon', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class PubgWeaponInfobox: WeaponInfobox
local CustomWeapon = Class.new(Weapon)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomWeapon.run(frame)
	local weapon = CustomWeapon(frame)
	weapon:setWidgetInjector(CustomInjector(weapon))

	return weapon:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Ammo Type', content = {args.ammotype}},
			Cell{name = 'Throw Speed', content = {args.throwspeed}},
			Cell{name = 'Throw Cooldown', content = {args.throwcooldown}},
			Cell{name = 'Maps', content = {args.maps}}
		)

		if String.isNotEmpty(args.map1) then
		local maps = {}

		for _, map in ipairs(self.caller:getAllArgsForBase(args, 'map')) do
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

---@param content string|number|Html|nil
---@return Html
function CustomWeapon:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end
return CustomWeapon
