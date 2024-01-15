---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')
local TableCell = Lua.import('Module:Widget/Table/Cell')
local TableRow = Lua.import('Module:Widget/Table/Row')
local WidgetTable = Lua.import('Module:Widget/Table')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomMap = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _map

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = Map(frame)
	_map = map
	_args = map.args
	map.addToLpdb = CustomMap.addToLpdb
	map.createWidgetInjector = CustomMap.createWidgetInjector
	return map:createInfobox()
end

---@return WidgetInjector
function CustomMap:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
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

---@return WidgetTableRow
function CustomMap:_createRingTableHeader()
	local headerRow = TableRow{css = {['font-weight'] = 'bold'}} -- bg needed
	return headerRow
		:addCell(TableCell{content = {'Ring'}})
		:addCell(TableCell{content = {'Wait (s)'}})
		:addCell(TableCell{content = {'Close<br>Time (s)'}})
		:addCell(TableCell{content = {'Damage<br>per tick'}})
		:addCell(TableCell{content = {'End Diameter (m)'}})
end

---@param ringData string
---@return WidgetTableRow
function CustomMap:_createRingTableRow(ringData)
	local row = TableRow{}
	for _, item in ipairs(mw.text.split(ringData, ',')) do
		row:addCell(TableCell{content = {item}})
	end
	return row
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.creator = mw.ext.TeamLiquidIntegration.resolve_redirect(args.creator or '')
	lpdbData.extradata.gamemode = args.gamemode
	lpdbData.extradata.competitive = String.isNotEmpty(args.spanstart) and String.isEmpty(args.spanend)
	return lpdbData
end

return CustomMap
