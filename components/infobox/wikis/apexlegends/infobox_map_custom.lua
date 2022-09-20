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
local WidgetTable = require('Module:Widget/Table')
local TableRow = require('Module:Widget/Table/Row')
local TableCell = require('Module:Widget/Table/Cell')

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
	else
		--If it never started being played competitively, it can't have an end date
		_args.spanend = nil
	end

	table.insert(widgets, Cell{
		name = 'Played in ALGS',
		content = {(_args.spanstart or '<i><b>Not </b></i>') .. spanText .. (_args.spanend or '<i><b>Currently</b></i>')}
	})

	if String.isNotEmpty(_args.ring) then
		local ringTable = WidgetTable{
			classes = {'fo-nttax-infobox' ,'wiki-bordercolor-light'}, --row alternating bg
			css = {['text-align'] = 'center',
				display = 'inline-grid !important',
				['padding-top'] = '0px',
				['padding-bottom'] = '0px',
				['border-top-style'] = 'none'},
			}
		ringTable:addRow(CustomMap:_createRingTableHeader())
		for _, ringData in ipairs(_map:getAllArgsForBase(_args, 'ring')) do
			ringTable:addRow(CustomMap:_createRingTableRow(ringData))
		end
		table.insert(widgets, Title{name = 'Ring Information'})
		table.insert(widgets, ringTable)
	end
	return widgets
end

function CustomMap:_createRingTableHeader()
	local headerRow = TableRow{css = {['font-weight'] = 'bold'}} -- bg needed
	return headerRow
		:addCell(TableCell{content = {'Ring'}})
		:addCell(TableCell{content = {'Wait (s)'}})
		:addCell(TableCell{content = {'Close<br>Time (s)'}})
		:addCell(TableCell{content = {'Damage<br>per tick'}})
		:addCell(TableCell{content = {'End Diameter (m)'}})
end

function CustomMap:_createRingTableRow(ringData)
	local row = TableRow{}
	for _, item in ipairs(mw.text.split(ringData, ',')) do
		row:addCell(TableCell{content = {item}})
	end
	return row
end

function CustomMap:addToLpdb(lpdbData)
	lpdbData.extradata.creator = mw.ext.TeamLiquidIntegration.resolve_redirect(_args.creator or '')
	lpdbData.extradata.gamemode = _args.gamemode
	lpdbData.extradata.competitive = String.isNotEmpty(_args.spanstart) and String.isEmpty(_args.spanend)
	return lpdbData
end

return CustomMap
