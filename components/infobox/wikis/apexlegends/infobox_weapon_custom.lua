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
local PageLink = require('Module:Page')

local CustomWeapon = Class.new()
local CustomInjector = Class.new(Injector)

local _weapon
local _args

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
	if String.isNotEmpty(args.basedamage) then
		local basedamages = {}
		for i, basedamage in ipairs(_weapon:getAllArgsForBase(args, 'basedamage')) do
			table.insert(basedamages, tostring(CustomWeapon:_createNoWrappingSpanDamage(basedamage, i
					)))
		end
		local basedamageconcat = table.concat(basedamages, '&nbsp;• ')
		if String.isEmpty(args.damage) then
			table.insert(widgets, Cell{
				name = 'Damage',
				content = {basedamageconcat}
			})
		end
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
		name = 'Projectile Speed',
		content = {args.projectilespeed}
	})
	if String.isNotEmpty(args.ammocapacity) then
		local ammocapacitys = {}
		for i, ammocapacity in ipairs(_weapon:getAllArgsForBase(args, 'ammocapacity')) do
			table.insert(ammocapacitys, tostring(CustomWeapon:_createNoWrappingSpanMagazine(ammocapacity, i
					)))
		end
		local ammocapacityconcat = table.concat(ammocapacitys, '<br>')
		if String.isEmpty(args.ammocap) then
			table.insert(widgets, Cell{
				name = 'Ammo Capacity',
				content = {ammocapacityconcat}
			})
		end
	end
	if String.isNotEmpty(args.reloadtime) then
		local reloadtimes = {}
		for i, reloadtime in ipairs(_weapon:getAllArgsForBase(args, 'reloadtime')) do
			table.insert(reloadtimes, tostring(CustomWeapon:_createNoWrappingSpanMagazine(reloadtime, i
					)))
		end
		local reloadtimeconcat = table.concat(reloadtimes, '<br>')
		if String.isEmpty(args.reloadspeed) then
			table.insert(widgets, Cell{
				name = 'Reload Speed',
				content = {reloadtimeconcat}
			})
		end
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
		for _, attachment in ipairs(_weapon:getAllArgsForBase(args, 'attachment')) do
			table.insert(attachments, tostring(CustomWeapon:_createNoWrappingSpanAttachment(attachment
					)))
		end
		table.insert(widgets, Title{name = 'Attachment Slots'})
		table.insert(widgets, Center{content = {table.concat(attachments, '&nbsp;&nbsp;')}})
	end
	if String.isNotEmpty(args.hopup) then
		local hopups = {}
		local hopupdescs = _weapon:getAllArgsForBase(args, 'hopupdesc')
		for i, hopup in ipairs(_weapon:getAllArgsForBase(args, 'hopup')) do
			table.insert(hopups, tostring(CustomWeapon:_createNoWrappingSpanHopUp(hopup)))
			table.insert(hopups, hopupdescs[i])
		end
		table.insert(widgets, Title{name = 'Hop-Ups'})
		table.insert(widgets, Center{content = {table.concat(hopups, '<br>')}})
	end
	return widgets
end

function CustomWeapon:_createNoWrappingSpanMagazine(content, i)
	local magazineInfo = {
		'&nbsp;<sup><strong></strong></sup>',
		'&nbsp;<sup><strong>[[with Common Ext. Mag|<span class="gray-theme-dark-bg"; style="font-family:monospace;color:white;padding:0 1px;">EXT</span>]]</strong></sup>',
		'&nbsp;<sup><strong>[[with Rare Ext. Mag|<span class="sapphire-a2"; style="font-family:monospace;color:white;padding:0 1px;">EXT</span>]]</strong></sup>',
		'&nbsp;<sup><strong>[[with Epic Ext. Mag|<span class="vivid-violet-theme-dark-bg"; style="font-family:monospace;color:white;padding:0 1px;">EXT</span>]] [[with Legendary Ext. Mag|<span class="bright-sun-0"; style="font-family:monospace;color:black;padding:0 1px;">EXT</span>]]</strong></sup>'
		}
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
		:node(magazineInfo[i])
	return span
end

function CustomWeapon:_createNoWrappingSpanDamage(content, i)
	local damageInfo = {
		'<sup><strong></strong></sup>',
		'&nbsp;<sup><strong><span class="gray-theme-dark-bg"; style="font-family:monospace;color:white;padding:0 1px;">Head</span></strong></sup>',
		'&nbsp;<sup><strong><span class="gray-theme-light-bg"; style="font-family:monospace;color:black;padding:0 1px;">Leg</span></strong></sup>',
		}
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
		:node(damageInfo[i])
	return span
end

function CustomWeapon:_createNoWrappingSpanAttachment(content)
	local fileName = "[[File:Apex ATTM_" .. content .. "_lightmode.png|60px|link=Portal:Attachments]]"
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(fileName)
	return span
end

function CustomWeapon:_createNoWrappingSpanHopUp(content)
	local fileName = "[[File:Apex ATTM_" .. content .. "_lightmode.png|60px|link=Portal:Attachments#Hop-Up Slot]]"
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(fileName)
	return span
end

function CustomWeapon:addToLpdb(lpdbData)
	lpdbData.extradata.class = _args.class
	lpdbData.extradata.description = _args.desc
	lpdbData.extradata.ammotype = _args.ammotype
	return lpdbData
end
return CustomWeapon
