---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class WarcraftMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class WarcraftMapInfoboxWidgetInjector: WidgetInjector
---@field caller WarcraftMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Tileset', content = {args.tileset}},
			Cell{name = 'Size', content = {(args.width or '') .. 'x' .. (args.height or '')}},
			Cell{name = 'Spawn Positions', content = {(args.players or '') .. ' at ' .. (args.positions or '')}},
			Cell{name = 'Versions', content = {String.convertWikiListToHtmlList(args.versions)}},
			Cell{name = 'Competition Span', content = {args.span}},
			Cell{name = 'Leagues Featured', content = {args.leagues}},
			Cell{name = 'Mercenary Camps', content = {
				self.caller:_mercenaryCamp(),
				self.caller:_mercenaryCamp(2),
				self.caller:_mercenaryCamp(3),
			}}
		)
	end

	return widgets
end

---@param postfix number|string|nil
---@return string?
function CustomMap:_mercenaryCamp(postfix)
	postfix = postfix or ''
	local campInput = self.args['merccamp' .. postfix]
	if not campInput then
		return nil
	end

	return Page.makeInternalLink({onlyIfExists = true}, campInput, 'Mercenary Camp#' .. campInput)
		or campInput
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.spawns = args.players
	lpdbData.extradata.height = args.height
	lpdbData.extradata.width = args.width
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
