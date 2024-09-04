---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/Cosmetic/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local CosmeticIcon = require('Module:Cosmetic')
local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Cosmetic = Lua.import('Module:Infobox/Cosmetic')

local Widgets = require('Module:Infobox/Widget/All')
local Builder = Widgets.Builder
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local SpecialCategories = {
	['Strange Modifier'] = 'Strange Modifier',
	['Ethereal'] = 'Ethereal',
	['Mastery'] = 'Mastery',
	['Kinetic'] = 'Kinetic',
	['Essence'] = 'Essence',
	['Immortal Treasure I'] = 'Immortal Treasure',
	['Trust of the Benefactor 20'] = 'Trust of the Benefactor',
	['Treasure of the Crimson Witness 20'] = 'Crimson Witness',
	['Baby Roshan'] = 'Baby Roshan',
}

---@class Dota2CosmeticInfobox: CosmeticInfobox
local CustomCosmetic = Class.new(Cosmetic)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCosmetic.run(frame)
	local cosmetic = CustomCosmetic(frame)
	cosmetic:setWidgetInjector(CustomInjector(cosmetic))
	cosmetic.args.subHeader = cosmetic.args.prefab
	cosmetic.args.imageText = 'ID: ' .. (cosmetic.args.defindex or 'N/A')

	return mw.html.create():node(cosmetic:createInfobox()):node(cosmetic:_createIntroText())
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		local slotText = ((args.slot == 'Persona' and '[[Persona]]') or (args.slot and String.upperCaseFirst(args.slot)))
		Array.appendWith(widgets,
			Cell{
				options = {columns = args.hero and 3 or 10, surpressColon = true},
				name = args.hero and Template.expandTemplate(mw.getCurrentFrame(), 'Hero entry', {args.hero}) or ' ',
				content = {
					'<b>Rarity:</b> ' .. Template.safeExpand(mw.getCurrentFrame(), 'Raritylink', {args.rarity}),
					args.slot and ('<b>Slot:</b> ' .. slotText) or nil,
				}
			},
			Center{content = {
				CustomCosmetic._buyNow(Logic.readBool(args.marketable or true), args.defindex)
			}},
			Title{name = 'Extra Information'},
			Cell{name = 'Created By', content =
				(args.creator == 'Valve' and {Template.safeExpand(mw.getCurrentFrame(), 'Valve icon')})
				or self.caller:getAllArgsForBase(args, 'creator')
			},
			Cell{name = 'Released', content = {
				Template.expandTemplate(mw.getCurrentFrame(), 'Patch link', {args.releasedate})
			}},
			Builder{builder = function()
				local ts = DateExt.readTimestamp(args.expiredate)
				if not ts then return {} end
				local name = 'Expires'
				if ts < DateExt.getCurrentTimestamp() then
					name = 'Expired'
				end
				return {
					Cell{name = name, content = {
						DateExt.formatTimestamp('j F Y', ts)
					}}
				}
			end},
			Builder{builder = function()
				local orgins = Array.parseCommaSeparatedString(args.availability or 'Unavailable')
				return {
					Cell{name = #orgins == 1 and 'Origin' or 'Origins', content = orgins}
				}
			end},
			Center{content = {args.description}},
			Center{name = '[[Trading|Tradable]]', classes = {'infobox-cosmetic-tradeable'}, content = {
				CustomCosmetic._ableText('TRADEABLE', args.tradeable, args.marketlock)
			}},
			Center{name = '[[Steam Community Market|Marketable]]', classes = {'infobox-cosmetic-marketable'}, content = {
				CustomCosmetic._ableText('MARKETABLE', args.marketable, args.marketlock)
			}},
			Center{name = '[[Deleting|Deletable]]', classes = {'infobox-cosmetic-deletable'}, content = {
				CustomCosmetic._ableText('DELETABLE', args.deletable)
			}}
		)
		Array.extendWith(widgets, CustomCosmetic._displaySet(args.setname, self.caller:getAllArgsForBase(args, 'setitem')))
	end

	return widgets
end

---@param setName string?
---@param manualItems string[]?
---@return Widget[]?
function CustomCosmetic._displaySet(setName, manualItems)
	local setItems = CustomCosmetic._createSet(setName, manualItems)
	if not setItems then
		return
	end

	return {
		Title{name = setName},
		Widgets.Highlights{content = Array.map(setItems, function(element)
			return '[['.. element ..']]'
		end)}
	}
end

---@param setName string?
---@param manualItems string[]?
---@return string[]?
function CustomCosmetic._createSet(setName, manualItems)
	if not setName then
		return
	end

	if Logic.isNotEmpty(manualItems) then
		return manualItems
	end

	return Json.parseIfString((mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::cosmetic_item]] and [[name::'.. setName ..']]',
		limit = 1,
	})[1] or {extradata = {}}).extradata.setitems)
end

---@param marketable boolean
---@param defindex string?
---@return string?
function CustomCosmetic._buyNow(marketable, defindex)
	local link

	if marketable and defindex then
		link = 'http://steamcommunity.com/market/search/?q=appid:570+prop_def_index:'.. defindex
	elseif marketable then
		link = 'http://steamcommunity.com/market/search/?q=appid:570+' .. (mw.title.getCurrentTitle().fullText:gsub(' ', '_'))
	else
		return
	end

	return '['.. link .. ' <span class="buynow_button buynow_market">Buy Now on Market</span>]'
end

---@param name string
---@param input string?
---@param marketlock string?
---@return string?
function CustomCosmetic._ableText(name, input, marketlock)
	if marketlock and DateExt.getCurrentTimestamp() < DateExt.readTimestamp(marketlock) then
		return name .. ' after ' .. marketlock
	end

	local canDo = Logic.readBoolOrNil(input or true)
	if canDo == true then
		return name
	elseif canDo == false then
		return 'NOT ' .. name
	end
end

function CustomCosmetic:_createIntroText()
	local args = self.args
	local firstSet = CustomCosmetic._createSet(args.setname, self:getAllArgsForBase(args, 'setitem'))

	if not firstSet then
		return
	end

	local output = mw.html.create()
	output:newline():wikitext('== Set Items =='):newline()
	output:node(CosmeticIcon._main{args.setname, '170px'})
	for _, item in ipairs(firstSet) do
		output:node(CosmeticIcon._main{item, '130px'})
	end

	local secondSet = CustomCosmetic._createSet(self.args.setname2)

	if not secondSet then
		return output
	end

	output:newline():wikitext('Also part of the following set:'):newline()
	output:node(CosmeticIcon._main{args.setname2, '170px'})
	for _, item in ipairs(secondSet) do
		output:node(CosmeticIcon._main{item, '130px'})
	end

	return output
end

function CustomCosmetic._getLpdbCategory(name)
	for key, value in pairs(SpecialCategories) do
		if string.find(key, name) then
			return value
		end
	end
end

function CustomCosmetic:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('cosmetic_item_' .. self.pagename, {
		name = args.name or self.pagename,
		type = 'cosmetic_item',
		image = args.image,
		imagedark = args.imagedark,
		date = args.releasedate,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			description = args.description or '',
			hero = args.hero or '',
			prefab = args.prefab or '',
			slot = args.slot or '',
			type = args.type or '',
			based_on = args['based on'] or '',
			rarity = args.rarity or '',
			creator = args.creator or '',
			defindex = args.defindex or '',
			availability = args.availability or '',
			marketlock = args.marketlock or '',
			setname = args.setname or '',
			setname2 = args.setname2 or '',
			setitems = self:getAllArgsForBase(args, 'setitem'),
			releasedate = args.releasedate or '',
			expiredate = args.expiredate or '',
			purchasable = tostring(Logic.readBoolOrNil(args.purchasable or true)),
			tradeable = tostring(Logic.readBoolOrNil(args.tradeable or true)),
			deletable = tostring(Logic.readBoolOrNil(args.deletable or true)),
			marketable = tostring(Logic.readBoolOrNil(args.marketable or true)),
			customizations = args.customizations or '',
			dotaplus = string.find(args.availability or '', 'Dota Plus') and 'true' or 'false',
			category = CustomCosmetic._getLpdbCategory(args.name or self.pagename),
			game = args.game or '',
		},
	})
end

return CustomCosmetic
