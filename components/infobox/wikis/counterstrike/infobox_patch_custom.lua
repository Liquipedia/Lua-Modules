---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local Game = Lua.import('Module:Game', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Patch = Lua.import('Module:Infobox/Patch', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomPatch = Class.new()

---@class WidgetInjectorCounterstrikePatch: WidgetInjector
local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local patch = Patch(frame)
	_args = patch.args

	patch.getChronologyData = CustomPatch.getChronologyData

	return patch:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]?
function CustomInjector:parse(id, widgets)
	if id == 'version' then
		local gameData =  Game.raw{game = _args.game, useDefault = false}
		table.insert(widgets, Cell{
			name = 'Game',
			content = {Page.makeInternalLink({}, gameData.name, gameData.link)}
		})
	end
	return widgets
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	local data = {}
	if args.previous then
		data.previous = 'Patch ' .. args.previous .. '|' .. args.previous
	end
	if args.next then
		data.next = 'Patch ' .. args.next .. '|' .. args.next
	end
	return data
end

function CustomPatch:getWikiCategories(args)
	local categories = {}
	local gameData =  Game.raw{game = args.game, useDefault = false}

	if gameData then
		table.insert(categories, (args.gameData.abbreviation or args.gameData.name) .. ' Patches')
	end

	return {}
end

return CustomPatch
