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
			table.insert(basedamages, tostring(CustomWeapon:_createNoWrappingSpanAttachment(basedamage, i, 'damage')))
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
			table.insert(ammocapacitys, tostring(CustomWeapon:_createNoWrappingSpanAttachment(ammocapacity, i, 'magazine')))
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
			table.insert(reloadtimes, tostring(CustomWeapon:_createNoWrappingSpanAttachment(reloadtime, i, 'magazine')))
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
		for i, attachment in ipairs(_weapon:getAllArgsForBase(args, 'attachment')) do
			table.insert(attachments, tostring(CustomWeapon:_createNoWrappingSpanAttachment(attachment, i, 'attachment')))
		end
		table.insert(widgets, Title{name = 'Attachment Slots'})
		table.insert(widgets, Center{content = {table.concat(attachments, '&nbsp;&nbsp;')}})
	end
	if String.isNotEmpty(args.hopup) then
		local hopups = {}
		local hopupdescs = _weapon:getAllArgsForBase(args, 'hopupdesc')
		for i, hopup in ipairs(_weapon:getAllArgsForBase(args, 'hopup')) do
			table.insert(hopups, tostring(CustomWeapon:_createNoWrappingSpanAttachment(hopup, i, 'attachment')))
			table.insert(hopups, hopupdescs[i])
		end
		table.insert(widgets, Title{name = 'Hop-Ups'})
		table.insert(widgets, Center{content = {table.concat(hopups, '<br>')}})
	end
	return widgets
end

local MAGAZINE_INFO = {
	{},
	{{text = 'with Common Ext. Mag|', bgClass = 'gray-theme-dark-bg', textBgClass = 'white-text'}},
	{{text = 'with Rare Ext. Mag|', bgClass = 'sapphire-a2', textBgClass = 'white-text'}},
	{
		{text = 'with Epic Ext. Mag|', bgClass = 'vivid-violet-theme-dark-bg', textBgClass = 'white-text'},
		{text = 'with Legendary Ext. Mag|', bgClass = 'bright-sun-0', textBgClass = 'black-text'}
	},
}

local DAMAGE_INFO = {
	{},
	{{text = 'Head', bgClass = 'gray-theme-dark-bg', textBgClass = 'white-text'}},
	{{text = 'Leg', bgClass = 'gray-theme-light-bg', textBgClass = 'black-text'}},
}

local NON_BREAKING_SPACE = '&nbsp;'

function CustomWeapon:_createNoWrappingSpanAttachment(content, i, type)
	local sup = mw.html.create('sup')
		:css('font-weigth', 'bold')
	if type == 'magazine' then
		local magazineInfo = MAGAZINE_INFO[i]
		if magazineInfo[1] then
			for index, info in ipairs(magazineInfo) do
				local span = mw.html.create('span')
					:addClass(info.bgClass)
					:addClass(info.textBgClass)
					:css('font-family', 'monospace')
					:css('padding', '0 1px')
					:wikitext('EXT')
				sup
					:wikitext(index ~=1 and ' ' or '')
					:wikitext('[[')
					:wikitext(info.text)
					:node(span)
					:wikitext(']]')
			end
		end
	elseif type == 'damage' then
		local damageInfo = DAMAGE_INFO[i]
		if damageInfo[1] then
			for index, info in ipairs(damageInfo) do
				local span = mw.html.create('span')
				sup
					:addClass(info.bgClass)
					:addClass(info.textBgClass)
					:css('font-family', 'monospace')
					:css('padding', '0 1px')
					:wikitext(index ~=1 and ' ' or '')
					:wikitext(info.text)
					:node(span)
			end
		end
	elseif type == 'attachment' then
		local fileName = '[[File:Apex ATTM_' .. content .. '_lightmode.png|60px|link=Portal:Attachments]]'
		local span = mw.html.create('span')
			:css('white-space', 'nowrap')
			:node(fileName)
		return span
	else
		local span = mw.html.create('span')
	end

	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
		:wikitext(NON_BREAKING_SPACE)
		:node(sup)
end

function CustomWeapon:addToLpdb(lpdbData)
	lpdbData.extradata.class = _args.class
	lpdbData.extradata.description = _args.desc
	lpdbData.extradata.ammotype = _args.ammotype
	return lpdbData
end
return CustomWeapon
