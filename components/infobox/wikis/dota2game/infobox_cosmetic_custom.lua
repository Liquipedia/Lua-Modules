---
-- @Liquipedia
-- wiki=dota2game
-- page=Module:Infobox/Cosmetic/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local CosmeticIcon = require('Module:Cosmetic')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
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

---@class Dota2CosmeticInfobox: CosmeticInfobox
local CustomCosmetic = Class.new(Cosmetic)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCosmetic.run(frame)
	local cosmetic = CustomCosmetic(frame)
	cosmetic:setWidgetInjector(CustomInjector(cosmetic))

	return mw.html.create():node(cosmetic:createInfobox()):node(cosmetic:_createIntroText())
end

-- TODO: Store LPDB

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{
				options = {columns = args.hero and 3 or 10, surpressColon = true},
				name = args.hero and Template.expandTemplate(mw.getCurrentFrame(), 'Hero entry', {args.hero}) or ' ',
				content = {
					'<b>Rarity:</b> ' .. Template.safeExpand(mw.getCurrentFrame(), 'Raritylink', {args.rarity}),
					args.slot and ('<b>Slot:</b> ' .. ((args.slot == 'Persona' and '[[Persona]]') or (args.slot and String.upperCaseFirst(args.slot)))) or nil,
				}
			},
			Center{content = {args.description}}, -- TODO Small and Italic?
			Title{name = 'Information'},
			Cell{name = 'Type (ID)', content = {(args.prefab or '') .. ' (' .. (args.defindex or 'N/A') .. ')'}},
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
					Title{name = #orgins == 1 and 'Origin' or 'Origins'},
					Center{content = {table.concat(orgins, '<br>')}}
				}
			end},
			Title{name = 'Properties'},
			Cell{name = '[[Trading|Tradable]]', content = {
				CustomCosmetic._ableCell(args.tradeable, args.marketlock)
			}},
			Cell{name = '[[Steam Community Market|Marketable]]', content = {
				CustomCosmetic._ableCell(args.marketable, args.marketlock)
			}},
			Cell{name = '[[Deleting|Deletable]]', content = {
				Logic.readBoolOrNil(args.deletable) == false and Icon.makeIcon{iconName = 'wrong'} or nil
			}},
			Center{content = {
				CustomCosmetic._buyNow(Logic.readBool(args.purchasable or true), Logic.readBool(args.marketable or true), args.defindex)
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

	return Array.parseCommaSeparatedString((mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::cosmetic_item]] and [[name::'.. setName ..']]',
		limit = 1,
	})[1] or {extradata = {}}).extradata.setitems)
end

---@param purchasable boolean
---@param marketable boolean
---@param defindex string?
---@return string?
function CustomCosmetic._buyNow(purchasable, marketable, defindex)
	if purchasable and defindex then
		return '[https://www.dota2.com/store/itemdetailsbydefindex/' .. defindex ..' <span class="buynow_button buynow_store">Buy Now in Store</span>]'
	elseif purchasable then
		return
	elseif marketable and defindex then
		return '[http://steamcommunity.com/market/search/?q=appid:570+prop_def_index:'.. defindex ..'<span class="buynow_button buynow_market">Buy Now on Market</span>]'
	elseif marketable then
		return '[http://steamcommunity.com/market/search/?q=appid:570+' .. mw.title.getCurrentTitle().fullText ..' <span class="buynow_button buynow_market">Buy Now on Market</span>]'
	end
end

---@param input string?
---@param marketlock string?
---@return string?
function CustomCosmetic._ableCell(input, marketlock)
	if marketlock then
		-- TODO: Format MarketLock
		-- TODO: Check if Marketlock is still valid
		return 'After ' .. marketlock
	end
	--- TODO: Make look more like ingame
	local canDo = Logic.readBoolOrNil(input or true)
	if canDo == true then
		return Icon.makeIcon{iconName = 'correct'}
	elseif canDo == false then
		return Icon.makeIcon{iconName = 'wrong'}
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

return CustomCosmetic
