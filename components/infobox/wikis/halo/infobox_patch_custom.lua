---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Patch = require('Module:Infobox/Patch')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local _args
local _game

local _GAME = mw.loadData('Module:GameVersion')

local CustomPatch = Class.new()
local CustomInjector = Class.new(Injector)

function CustomPatch.run(frame)
	local customPatch = Patch(frame)
	_args = customPatch.args
	customPatch.createWidgetInjector = CustomPatch.createWidgetInjector
	customPatch.getChronologyData = CustomPatch.getChronologyData
	customPatch.addToLpdb = CustomPatch.addToLpdb
	return customPatch:createInfobox(frame)
end

function CustomPatch:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Game Version',
		content = {CustomPatch._getGameVersion()},
		options = {makeLink = true}
	})
	return widgets
end

function CustomPatch:addToLpdb(lpdbData)
	mw.ext.LiquipediaDB.lpdb_datapoint('patch_' .. self.name, {
		name = _args.name,
		type = 'patch',
		information = CustomPatch:_getGameVersion(),
		date = _args.release,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			version = _args.version,
		}
	})
	return lpdbData
end

function CustomPatch:getChronologyData()
	local data = {}
	if _args.previous then
		data.previous = _args.previous .. ' Patch|' .. _args.previous_link
	end
	if _args.next then
		data.next = _args.next .. ' Patch|' .. _args.next_link
	end
	return data
end

function CustomPatch._getGameVersion()
	local game = string.lower(_args.game or '')
	_game = _GAME[game]
	return _game
end
return CustomPatch
