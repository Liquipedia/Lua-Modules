---
-- @Liquipedia
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local Injector = Lua.import('Module:Widget/Injector')
local Weapon = Lua.import('Module:Infobox/Weapon')

---@class ApexlegendsWeaponInfobox: WeaponInfobox
local CustomWeapon = Class.new(Weapon)
local CustomInjector = Class.new(Injector)

local MAGAZINE_INFO = {
	{},
	{{text = '[[with Common Ext. Mag|<span class="white-text">EXT</span>]]', bgClass = 'gray-theme-dark-bg'}},
	{{text = '[[with Rare Ext. Mag|<span class="white-text">EXT</span>]]', bgClass = 'sapphire-a2'}},
	{
		{text = '[[with Epic Ext. Mag|<span class="white-text">EXT</span>]]', bgClass = 'vivid-violet-theme-dark-bg'},
		{text = '[[with Legendary Ext. Mag|<span class="black-text">EXT</span>]]', bgClass = 'bright-sun-0'}
	},
}
local BOLT_INFO = {
	{},
	{{text = '[[with Common Shotgun Bolt|<span class="white-text">EXT</span>]]', bgClass = 'gray-theme-dark-bg'}},
	{{text = '[[with Rare Shotgun Bolt|<span class="white-text">EXT</span>]]', bgClass = 'sapphire-a2'}},
	{{text = '[[with Epic Shotgun Bolt|<span class="white-text">EXT</span>]]', bgClass = 'vivid-violet-theme-dark-bg'}},
}
local DAMAGE_INFO = {
	{},
	{{text = 'Head', bgClass = 'gray-theme-dark-bg', textBgClass = 'white-text'}},
	{{text = 'Leg', bgClass = 'gray-theme-light-bg', textBgClass = 'black-text'}},
}
local NON_BREAKING_SPACE = '&nbsp;'

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
	local args = self.caller.args

	if id == 'custom' then
		local fetchCustomValues = function(key1, key2, lookUpTable)
			if String.isEmpty(args[key1]) or String.isNotEmpty(args[key2]) then
				return {}
			end

			local values = Array.map(self.caller:getAllArgsForBase(args, key1), function(item, index)
				return self.caller:_createContextualNoWrappingSpan(item, index, lookUpTable)
			end)

			if String.isNotEmpty(args[key1 .. 'note']) then
				table.insert(values, self.caller:_createContextualNote(args[key1 .. 'note']))
			end

			return values
		end

		Array.appendWith(
			widgets,
			Cell{name = 'Damage', content = fetchCustomValues('basedamage', 'damage', DAMAGE_INFO)},
			Cell{name = 'Rates of Fire', content = fetchCustomValues('ratesoffire', 'rateoffireauto', BOLT_INFO)},
			Cell{name = 'Ammo Capacity', content = fetchCustomValues('ammocapacity', 'ammocap', MAGAZINE_INFO)},
			Cell{name = 'Reload Speed', content = fetchCustomValues('reloadtime', 'reloadspeed', MAGAZINE_INFO)}
		)

		if String.isNotEmpty(args.ammotype) and String.isNotEmpty(args.ammotypeicon) then
			table.insert(widgets, Cell{name = 'Ammo Type', content = {args.ammotypeicon .. ' ' .. args.ammotype}})
		end

		if String.isNotEmpty(args.attachment) then
			local attachments = {}
			for index, attachment in ipairs(self.caller:getAllArgsForBase(args, 'attachment')) do
				table.insert(attachments, self.caller:_createContextualNoWrappingSpan(attachment, index))
			end
			table.insert(widgets, Title{children = 'Attachment Slots'})
			table.insert(widgets, Center{children = {table.concat(attachments, '&nbsp;&nbsp;')}})
		end

		if String.isNotEmpty(args.hopup) then
			local hopups = {}
			args.hopupdesc1 = args.hopupdesc1 or args.hopupdesc
			for index, hopup in ipairs(self.caller:getAllArgsForBase(args, 'hopup')) do
				table.insert(hopups, self.caller:_createContextualNoWrappingSpan(hopup, index))
				table.insert(hopups, args['hopupdesc' .. index])
			end
			table.insert(widgets, Title{children = 'Hop-Ups'})
			table.insert(widgets, Center{children = {table.concat(hopups, '<br>')}})
		end

		Array.appendWith(
			widgets,
			Cell{name = 'Rate of fire (Single)', content = {args.rateoffiresingle}},
			Cell{name = 'Rate of fire (Auto)', content = {args.rateoffireauto}},
			Cell{name = 'Rate of fire (Burst)', content = {args.rateoffireburst}},
			Cell{name = 'Projectile Speed', content = {args.projectilespeed}},
			Cell{name = 'Range', content = {args.range}},
			Cell{name = 'Ignition Time', content = {args.ignitiontime}},
			Cell{name = 'Release Date', content = {args.release}}
		)
	end

	return widgets
end

---@param content Html|string|number|nil
---@param index integer
---@param lookUpTable table[]
---@return string?
function CustomWeapon:_createContextualNoWrappingSpan(content, index, lookUpTable)
	if not lookUpTable then
		local page = 'link=Portal:Attachments'
		local icon = '[[File:Apex ATTM_' .. content .. '_lightmode.png|60px|'.. page ..'|class=show-when-light-mode]]'
		local iconDark = '[[File:Apex ATTM_' .. content .. '_darkmode.png|60px|'.. page ..'|class=show-when-dark-mode]]'
		local returnSpan = mw.html.create('span')
			:css('white-space', 'nowrap')
			:node(icon)
			:node(iconDark)
		return tostring(returnSpan)
	elseif not lookUpTable[index] then
		return
	end

	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
		:wikitext(NON_BREAKING_SPACE)

	for infoIndex, info in ipairs(lookUpTable[index]) do
		local sup = mw.html.create('sup')
			:css('font-weigth', 'bold')
			:addClass(info.bgClass)
			:addClass(info.textBgClass)
			:css('font-family', 'monospace')
			:css('padding', '0 1px')
			:wikitext(info.text)

		span
			:wikitext(infoIndex ~= 1 and ' ' or '')
			:node(sup)
	end

	return tostring(span)
end

---@param noteText string|number
---@return string
function CustomWeapon:_createContextualNote(noteText)
	return '<span style="font-size:80%">' .. noteText .. '</span>'
end

---@param lpdbData table
---@param args table
---@return table
function CustomWeapon:addToLpdb(lpdbData, args)
	lpdbData.extradata.class = args.class
	lpdbData.extradata.description = args.desc
	lpdbData.extradata.ammotype = args.ammotype
	return lpdbData
end

return CustomWeapon
