---
-- @Liquipedia
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local MessageBox = require('Module:Message box')

local Injector = Lua.import('Module:Widget/Injector')
local Item = Lua.import('Module:Infobox/Item')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class StormgateItemInfobox: ItemInfobox
---@field data table
local CustomItem = Class.new(Item)
local CustomInjector = Class.new(Injector)

local ICON_DEPRECATED = '[[File:Cancelled Tournament.png|link=]]'
local VALID_ITEMS = {
	'Gear',
}

---@param frame Frame
---@return Html
function CustomItem.run(frame)
	local item = CustomItem(frame)

	assert(Table.includes(VALID_ITEMS, item.args.informationType), 'Missing or invalid "informationType"')

	item:setWidgetInjector(CustomInjector(item))

	item.data = {
		introduced = item:_processPatchFromId(item.args.introduced),
		deprecated = item:_processPatchFromId(item.args.deprecated),
	}

	local builtInfobox = item:createInfobox()

	return mw.html.create()
		:node(builtInfobox)
		:node(CustomItem._deprecatedWarning(item.data.deprecated.display))
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'info' then
		return {
			Title{children = args.informationType .. ' Information'},
			Cell{name = 'Slot', content = {tonumber(args.slot)}},
			Cell{name = 'Introduced', content = {caller.data.introduced.display}}
		}
	elseif id == 'availability' then
		return {
			Title{children = 'Availability'},
			Cell{name = 'Faction', content = {CustomItem._getFactionsDisplay(args.faction)}},
			Cell{name = 'Unlocked', content = {CustomItem._getUnlockedDisplay(args.unlocked)}},
		}
	elseif id == 'recipe' then
		return {
			Title{children = 'Tags'},
			Center{children = {CustomItem._getTagsDisplay(args.tags)}}
		}
	elseif Table.includes({'attributes', 'ability', 'maps', 'recipe'}, id) then
		return {}
	end

	return widgets
end

---@param factionArgs string
---@return string?
function CustomItem._getFactionsDisplay(factionArgs)
	local parsedFactionArgs = Array.map(Array.parseCommaSeparatedString(factionArgs), Faction.read)

	if Array.all(Faction.coreFactions, function(faction)
		return Table.includes(parsedFactionArgs, faction)
	end) then return 'any' end

	local factions = Array.map(Faction.coreFactions, function(faction)
		return Table.includes(parsedFactionArgs, faction) and faction or nil
	end)

	return table.concat(Array.map(factions, function(faction)
		return Faction.Icon{faction = faction}
	end), ' ')
end

---@param unlockedArgs string
---@return string?
function CustomItem._getUnlockedDisplay(unlockedArgs)
	local parsedUnlockedArgs = Array.parseCommaSeparatedString(unlockedArgs, ':')

	local hero = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::Hero]] AND [[pagename::' .. parsedUnlockedArgs[1] .. '/Coop]]',
		order = 'name asc',
		query = 'information, type, name, pagename, extradata',
		limit = 1,
	})[1] or {}

	if type(hero) ~= 'table' or Logic.isEmpty(hero) then return nil end

	return Page.makeInternalLink({}, hero.name, hero.pagename) .. ' level ' .. parsedUnlockedArgs[2]
end


---@param tagArgs string
---@return string?
function CustomItem._getTagsDisplay(tagArgs)
	local tags = Array.sortBy(Array.parseCommaSeparatedString(tagArgs), function(item)
		return tostring(item)
	end)

	return table.concat(Array.map(tags, function(tag)
		return Page.makeInternalLink({onlyIfExists=true}, tag, tag) or tag
	end), ', ')
end

---@return string[]
function CustomItem:getWikiCategories()
	return {'Gear'}
end

---@param args table
function CustomItem:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('item_' .. self.pagename, {
		name = args.name,
		type = args.informationType,
		--information = --currently unused
		image = args.image,
		imagedark = args.imagedark,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			deprecated = self.data.deprecated.store or '',
			introduced = self.data.introduced.store or '',
			faction = Array.parseCommaSeparatedString(args.faction),
			subfaction = Array.parseCommaSeparatedString(args.subfaction),
			slot = tonumber(args.slot),
			unlocked = args.unlocked,
			tags = Array.parseCommaSeparatedString(args.tags),
		},
	})
end

---@param input string?
---@return {store: string?, display: string?}
function CustomItem:_processPatchFromId(input)
	if String.isEmpty(input) then return {} end

	local patches = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::patch]]',
		limit = 5000,
	})

	local patchPage = (Array.filter(patches, function(patch)
		return String.endsWith(patch.pagename, '/' .. input)
	end)[1] or {}).pagename
	assert(patchPage, 'Invalid patch "' .. input .. '"')

	return {
		store = patchPage,
		display = Page.makeInternalLink(input, patchPage),
	}
end

---@param patch string?
---@return Html?
function CustomItem._deprecatedWarning(patch)
	if not patch then return end

	return MessageBox.main('ambox', {
		image = ICON_DEPRECATED,
		class ='ambox-red',
		text = 'This has been removed with Patch ' .. patch,
	})
end

return CustomItem
