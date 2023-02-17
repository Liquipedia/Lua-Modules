---
-- @Liquipedia
-- wiki=heroes
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Title = Widgets.Title
local Center = Widgets.Center

local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league

	league.createWidgetInjector = CustomLeague.createWidgetInjector

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'customcontent' then
		local maps = Array.map(_league:getAllArgsForBase(_league.args, 'bg'), function(map)
			return tostring(CustomLeague:_createNoWrappingSpan(PageLink.makeInternalLink(map)))
		end)

		if #maps > 0 then
			table.insert(widgets, Title{name = 'Battlegrounds'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	end

	return widgets
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
