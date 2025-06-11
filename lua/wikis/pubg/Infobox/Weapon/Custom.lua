---
-- @Liquipedia
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Weapon = Lua.import('Module:Infobox/Weapon')

local Widgets = require('Module:Widget/All')
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
			Cell{name = 'Throw Cooldown', content = {args.throwcooldown}}
		)

		if String.isEmpty(args.map1) then
			return widgets
		end

		local maps = Array.map(self.caller:getAllArgsForBase(args, 'map'), function(map)
			return tostring(CustomWeapon:_createNoWrappingSpan(PageLink.makeInternalLink({}, map)))
		end)

		table.insert(widgets, Title{children = 'Maps'})
		table.insert(widgets, Center{children = {table.concat(maps, '&nbsp;• ')}})
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
