---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Map = require('Module:Infobox/Map')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local String = require('Module:StringUtils')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local CustomMap = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _map

function CustomMap.run(frame)
	local map = Map(frame)
	_map = map
	_args = map.args
	map.addToLpdb = CustomMap.addToLpdb
	map.createWidgetInjector = CustomMap.createWidgetInjector
	return map:createInfobox(frame)
end

function CustomMap:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Game Mode(s)',
		content = {_args.gamemode}
	})

	local spanText = ''
	if String.isNotEmpty(_args.spanstart) then
		spanText = spanText .. ' - '
	end

	table.insert(widgets, Cell{
		name = 'Played in ALGS',
		content = {(_args.spanstart or '<i><b>Not </b></i>') .. spanText .. (_args.spanend or '<i><b>Currently</b></i>')}
	})

	if String.isNotEmpty(_args.ring) then
		local ringTable = mw.html.create('table')
			:addClass('wikitable wikitable-striped wikitable-bordered')
			:css('width', '100%')
			:css('text-align', 'center')
		ringTable:node(CustomMap:_createRingTable())
		for _, rings in ipairs(_map:getAllArgsForBase(_args, 'ring')) do
			ringTable:node(CustomMap:_createRingTable(rings))
		end
		table.insert(widgets, Title{name = 'Ring Information'})
		table.insert(widgets, Center{content = {tostring(ringTable)}})
	end

	return widgets
end

function CustomMap:_createRingTable(content)
	local row = mw.html.create('tr')

	if not content then
		row
			:tag('th'):wikitext('Ring'):done()
			:tag('th'):wikitext('Wait(s)'):done()
			:tag('th'):wikitext('Close<br>Time(s)'):done()
			:tag('th'):wikitext('Damage<br>per tick'):done()
			:tag('th'):wikitext('End Diameter (m)'):done()
	else
		for _, item in ipairs(mw.text.split(content, ',')) do
			row:tag('td'):wikitext(item):done()
		end
	end
	return row:done()
end

function CustomMap:addToLpdb(lpdbData)
	lpdbData.extradata.creator = mw.ext.TeamLiquidIntegration.resolve_redirect(_args.creator)
	lpdbData.extradata.gamemode = _args.gamemode
	if String.isNotEmpty(_args.spanstart) and String.isEmpty(_args.spanend) then
		lpdbData.extradata.competitive = true
	else
		lpdbData.extradata.competitive = false
	end
	return lpdbData
end

return CustomMap
