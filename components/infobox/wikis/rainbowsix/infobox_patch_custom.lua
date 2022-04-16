---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Patch = require('Module:Infobox/Patch')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local CustomPatch = Class.new()
local CustomInjector = Class.new(Injector)

local _args

function CustomPatch.run(frame)
	local customPatch = Patch(frame)
	_args = customPatch.args
	customPatch.createWidgetInjector = CustomPatch.createWidgetInjector
	return customPatch:createInfobox(frame)
end

function CustomPatch:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'release' then
		return {
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

return CustomPatch
