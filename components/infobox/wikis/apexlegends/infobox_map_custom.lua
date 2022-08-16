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
	local spantext = ''
	if String.isNotEmpty(_args.spanstart) then
		spantext = spantext .. ' - '
	end
	table.insert(widgets, Cell{
		name = 'Played in ALGS',
		content = {(_args.spanstart or '<i><b>Not </b></i>') .. spantext .. (_args.spanend or '<i><b>Currently</b></i>')}
	})
	if String.isNotEmpty(_args.ring) then
		local ringTable = mw.html.create('table')
			:addClass('wikitable wikitable-striped wikitable-bordered')
			:css('width', '325px')
			:css('text-align', 'center')
		CustomMap:_createRingTable(ringTable)
		for _, rings in ipairs(_map:getAllArgsForBase(_args, 'ring')) do
			ringTable:node(CustomMap:_createRingTable(rings))
		end
		table.insert(widgets, Title{name = 'Ring Information'})
		table.insert(widgets, Center{content = {tostring(ringTable)}})
	end
	return widgets
end

function CustomMap:_createRingTable(ringTable, content)
	local row = mw.html.create('tr')

	if not content then
		row:tag('th')
			:wikitext('Ring')
			:css('text-align', 'center')
		row:tag('th')
			:wikitext('Wait(s)')
			:css('text-align', 'center')
		row:tag('th')
			:wikitext('Close<br>Time(s)')
			:css('text-align', 'center')
		row:tag('th')
			:wikitext('Damage<br>per tick')
			:css('text-align', 'center')
		row:tag('th')
			:wikitext('End Diameter (m)')
			:css('text-align', 'center')
	else
		local parameters = mw.text.split(content, ',')
		row:tag('td')
			:wikitext(parameters[1])
			:css('text-align', 'center')
		row:tag('td')
			:wikitext(parameters[2])
			:css('text-align', 'center')
		row:tag('td')
			:wikitext(parameters[3])
			:css('text-align', 'center')
		row:tag('td')
			:wikitext(parameters[4])
			:css('text-align', 'center')
		row:tag('td')
			:wikitext(parameters[5])
			:css('text-align', 'center')
	end
	return row:done()
end

function CustomMap:addToLpdb(lpdbData)
	lpdbData.extradata.creator = mw.ext.TeamLiquidIntegration.resolve_redirect(_args.creator)
	lpdbData.extradata.gamemode = _args.gamemode
	if ((String.isNotEmpty(_args.spanstart) and _args.spanstart ~= '')
	and (String.isEmpty(_args.spanend) or _args.spanend == '')) then
		lpdbData.extradata.competitive = true
	else
		lpdbData.extradata.competitive = false
	end
	return lpdbData
end

return CustomMap
