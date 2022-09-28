---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Patch = Lua.import('Module:Infobox/Patch', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _args

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

function CustomInjector:parse(id, widgets)
	if id == 'release' then
		return {
			Cell{
				name = 'Release Date',
				content = {_args.release}
			},
			Cell{
				name = 'PC Release Date',
				content = {_args.pcrelease}
			},
			Cell{
				name = 'Console Release Date',
				content = {_args.consolerelease}
			},
		}
	end
	return widgets
end

function CustomPatch:addToLpdb(lpdbData)
	local date = _args.release or _args.pcrelease or _args.consolerelease
	mw.ext.LiquipediaDB.lpdb_datapoint('patch_' .. self.name, {
		name = _args.name,
		type = 'patch',
		information = _args.game,
		date = date,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			version = _args.version,
		}
	})
	return lpdbData
end

function CustomPatch:getChronologyData()
	local data = {}
	if _args.previous then
		data.previous = _args.previous .. ' Patch|' .. _args.previous
	end
	if _args.next then
		data.next = _args.next .. ' Patch|' .. _args.next
	end
	return data
end

return CustomPatch
