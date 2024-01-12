---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local ModeIcon = require('Module:ModeIcon')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local CustomMap = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _map

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local customMap = Map(frame)
	_map = customMap
	_args = customMap.args

	customMap.createWidgetInjector = CustomMap.createWidgetInjector

	return mw.html.create()
		:node(customMap:createInfobox())
		:node(CustomMap._intro(_args))
end

---@param args table
---@return Html
function CustomMap._intro(args)
	local modes = CustomMap._getModes(args)

	local intro = mw.html.create()
		:tag('b'):wikitext(_map.name):done()
		:wikitext(' is a map')
		:wikitext(modes and (' for ' .. mw.text.listToText(modes)) or '')
		:wikitext(' in '):done()
		:tag('i'):wikitext('Brawl Stars'):done()
		:wikitext('.')

	local alsoKnownAs = _map:getAllArgsForBase(args, 'aka')

	if Table.isEmpty(alsoKnownAs) then
		return intro
	end

	alsoKnownAs = Array.map(alsoKnownAs, function(aka) return '<b>' .. aka .. '</b>' end)

	return intro:wikitext(' The map was formerly known as ')
		:wikitext(mw.text.listToText(alsoKnownAs) .. '.')
end

---@return WidgetInjector
function CustomMap:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	local modes = CustomMap._getModes(_args)

	Array.appendWith(widgets,
		Cell{name = 'Environment', content = {_args.environment}},
		Title{name = modes and 'Mode' or nil},
		Center{content = modes and {table.concat(modes, '<br>')} or nil}
	)

	return widgets
end

---@param args table
---@return string[]?
function CustomMap._getModes(args)
	local modes = _map:getAllArgsForBase(args, 'mode')

	if Table.isEmpty(modes) then return end

	return Array.map(modes, ModeIcon.run)
end

return CustomMap
