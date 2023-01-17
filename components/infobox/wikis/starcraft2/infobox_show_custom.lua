---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Show = Lua.import('Module:Infobox/Show', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomShow = Class.new()

local _args

local CustomInjector = Class.new(Injector)

function CustomShow.run(frame)
	local customShow = Show(frame)
	_args = customShow.args
	customShow.createWidgetInjector = CustomShow.createWidgetInjector
	customShow.getWikiCategories = CustomShow.getWikiCategories
	return customShow:createInfobox(frame)
end

function CustomShow:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'No. of episodes',
		content = {_args['num_episodes']}
	})
	table.insert(widgets, Cell{
		name = 'Original Release',
		content = {CustomShow:_getReleasePeriod(_args.sdate, _args.edate)}
	})

	return widgets
end

function CustomShow:_getReleasePeriod(sdate, edate)
	if not sdate then return nil end
	return sdate .. ' - ' .. (edate or '<b>Present</b>')
end

function CustomShow:getWikiCategories(args)
	return _args.edate and {} or {'Active Shows'}
end

return CustomShow
