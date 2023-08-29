---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Map = Lua.import('Module:Infobox/Map', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomMap = Class.new()

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local customMap = Map(frame)

	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	customMap.getWikiCategories = CustomMap.getWikiCategories
	customMap.addToLpdb = CustomMap.addToLpdb

	_args = customMap.args
	return customMap:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	Array.appendWith(widgets,
		Cell{name = 'Tileset', content = {_args.tileset}},
		Cell{name = 'Size', content = {(_args.width or '') .. 'x' .. (_args.height or '')}},
		Cell{name = 'Spawn Positions', content = {(_args.players or '') .. ' at ' .. (_args.positions or '')}},
		Cell{name = 'Versions', content = {String.convertWikiListToHtmlList(_args.versions)}},
		Cell{name = 'Competition Span', content = {_args.span}},
		Cell{name = 'Leagues Featured', content = {_args.leagues}},
		Cell{name = 'Mercenary Camps', content = {
			CustomMap._mercenaryCamp(),
			CustomMap._mercenaryCamp(2),
			CustomMap._mercenaryCamp(3),
		}}
	)

	return widgets
end

---@param postfix number|string|nil
---@return string?
function CustomMap._mercenaryCamp(postfix)
	postfix = postfix or ''
	local campInput = _args['merccamp' .. postfix]
	if not campInput then
		return nil
	end

	return Page.makeInternalLink({onlyIfExists = true}, campInput, 'Mercenary Camp#' .. campInput)
		or campInput
end

---@return WidgetInjector
function CustomMap:createWidgetInjector()
	return CustomInjector()
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata = {
		creator = args.creator,
		spawns = args.players,
		height = args.height,
		width = args.width,
	}
	return lpdbData
end

---@param args table
---@return string[]
function CustomMap:getWikiCategories(args)
	if String.isEmpty(args.players) then
		return {'InfoboxIncomplete'}
	end

	return {'Maps (' .. args.players .. ' Players)'}
end

return CustomMap
