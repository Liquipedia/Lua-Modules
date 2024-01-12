---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
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

---@class ApexMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)

	map:setWidgetInjector(CustomInjector(map))
	return map:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Game Mode(s)', content = {args.gamemode}},
			Cell{name = 'Played in ALGS', content = {self.caller:createSpan(args)}}
		)

		if String.isEmpty(args.ring) then return widgets end

		local ringTable = WidgetTable{
			classes = {'fo-nttax-infobox' ,'wiki-bordercolor-light'}, --row alternating bg
			css = {
				['text-align'] = 'center',
				display = 'inline-grid !important',
				['padding-top'] = '0px',
				['padding-bottom'] = '0px',
				['border-top-style'] = 'none',
			},
		}

		ringTable:addRow(self.caller:createRingTableHeader())

		Array.forEach(self.caller:getAllArgsForBase(args, 'ring'), function(ringData)
			ringTable:addRow(self.caller:createRingTableRow(ringData))
		end)

		Array.appendWith(widgets,
			Title{name = 'Ring Information'},
			ringTable
		)
	end

	return widgets
end

---@return WidgetTableRow
function CustomMap:createRingTableHeader()
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
function CustomMap:createRingTableRow(ringData)
	local row = TableRow{}
	for _, item in ipairs(mw.text.split(ringData, ',')) do
		row:addCell(TableCell{content = {item}})
	end
	return row
end

---@param args table
---@return table
function CustomMap:createSpan(args)
	local spanText = ''
	if String.isNotEmpty(args.spanstart) then
		spanText = spanText .. ' - '
	else
		--If it never started being played competitively, it can't have an end date
		args.spanend = nil
	end

	return (args.spanstart or '<i><b>Not </b></i>') .. spanText .. (args.spanend or '<i><b>Currently</b></i>')
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
