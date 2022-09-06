---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Infobox/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Weapon = require('Module:Infobox/Weapon')
local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local CustomWeapon = Class.new()
local CustomInjector = Class.new(Injector)

local _weapon
local _args

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
	local args = _args
	if String.isNotEmpty(args.basedamage) and String.isEmpty(args.damage) then
		local baseDamages = {}
		for index, baseDamage in ipairs(_weapon:getAllArgsForBase(args, 'basedamage')) do
			table.insert(baseDamages, CustomWeapon:_createContextualNoWrappingSpan(baseDamage, index, DAMAGE_INFO))
		end
		if String.isNotEmpty(args.basedamagenote) then
			local noteString = '<span style="font-size:80%">' .. args.basedamagenote .. '</span>'
			table.insert(baseDamages, noteString)
		end
		table.insert(widgets, Cell{
			name = 'Damage',
			content = {table.concat(baseDamages, '<br>')}
		})
	end

	table.insert(widgets, Cell{
		name = 'Rate of fire (Single)',
		content = {args.rateoffiresingle}
	})

	table.insert(widgets, Cell{
		name = 'Rate of fire (Auto)',
		content = {args.rateoffireauto}
	})

	table.insert(widgets, Cell{
		name = 'Rate of fire (Burst)',
		content = {args.rateoffireburst}
	})

	if String.isNotEmpty(args.ratesoffire) and String.isEmpty(args.ratesoffireauto) then
		local rofTimes = {}
		for index, rofTime in ipairs(_weapon:getAllArgsForBase(args, 'ratesoffire')) do
			table.insert(rofTimes, CustomWeapon:_createContextualNoWrappingSpan(rofTime, index, BOLT_INFO))
		end
		if String.isNotEmpty(args.ratesoffirenote) then
			local noteString = '<span style="font-size:80%">' .. args.ratesoffirenote .. '</span>'
			table.insert(rofTimes, noteString)
		end
		table.insert(widgets, Cell{
			name = 'Rates of Fire',
			content = {table.concat(rofTimes, '<br>')}
		})
	end

	table.insert(widgets, Cell{
		name = 'Projectile Speed',
		content = {args.projectilespeed}
	})

	if String.isNotEmpty(args.ammocapacity) and String.isEmpty(args.ammocap) then
		local ammoSizes = {}
		for index, ammoSize in ipairs(_weapon:getAllArgsForBase(args, 'ammocapacity')) do
			table.insert(ammoSizes, CustomWeapon:_createContextualNoWrappingSpan(ammoSize, index, MAGAZINE_INFO))
		end
		if String.isNotEmpty(args.ammocapacitynote) then
			local noteString = '<span style="font-size:80%">' .. args.ammocapacitynote .. '</span>'
			table.insert(ammoSizes, noteString)
		end
		table.insert(widgets, Cell{
			name = 'Ammo Capacity',
			content = {table.concat(ammoSizes, '<br>')}
		})
	end

	if String.isNotEmpty(args.reloadtime) and String.isEmpty(args.reloadspeed) then
		local reloadTimes = {}
		for index, reloadTime in ipairs(_weapon:getAllArgsForBase(args, 'reloadtime')) do
			table.insert(reloadTimes, CustomWeapon:_createContextualNoWrappingSpan(reloadTime, index, MAGAZINE_INFO))
		end
		if String.isNotEmpty(args.reloadtimenote) then
			local noteString = '<span style="font-size:80%">' .. args.reloadtimenote .. '</span>'
			table.insert(reloadTimes, noteString)
		end
		table.insert(widgets, Cell{
			name = 'Reload Speed',
			content = {table.concat(reloadTimes, '<br>')}
		})
	end

	table.insert(widgets, Cell{
		name = 'Ammo Type',
		content = {args.ammotypeicon .. ' ' .. args.ammotype}
	})

	table.insert(widgets, Cell{
		name = 'Release Date',
		content = {args.release}
	})

	if String.isNotEmpty(args.attachment) then
		local attachments = {}
		for index, attachment in ipairs(_weapon:getAllArgsForBase(args, 'attachment')) do
			table.insert(attachments, CustomWeapon:_createContextualNoWrappingSpan(attachment, index))
		end
		table.insert(widgets, Title{name = 'Attachment Slots'})
		table.insert(widgets, Center{content = {table.concat(attachments, '&nbsp;&nbsp;')}})
	end

	if String.isNotEmpty(args.hopup) then
		local hopups = {}
		args.hopupdesc1 = args.hopupdesc1 or args.hopupdesc
		for index, hopup in ipairs(_weapon:getAllArgsForBase(args, 'hopup')) do
			table.insert(hopups, CustomWeapon:_createContextualNoWrappingSpan(hopup, index))
			table.insert(hopups, args['hopupdesc' .. index])
		end
		table.insert(widgets, Title{name = 'Hop-Ups'})
		table.insert(widgets, Center{content = {table.concat(hopups, '<br>')}})
	end
	return widgets
end

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
			:wikitext(infoIndex ~=1 and ' ' or '')
			:node(sup)
	end

	return tostring(span)
end

function CustomWeapon:addToLpdb(lpdbData)
	lpdbData.extradata.class = _args.class
	lpdbData.extradata.description = _args.desc
	lpdbData.extradata.ammotype = _args.ammotype
	return lpdbData
end
return CustomWeapon
