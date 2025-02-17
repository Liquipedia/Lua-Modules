---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local UnofficialWorldChampion = Lua.import('Module:Infobox/UnofficialWorldChampion')

local Widgets = require('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class OverwatchUnofficialWorldChampionInfobox: UnofficialWorldChampionInfobox
local CustomUnofficialWorldChampion = Class.new(UnofficialWorldChampion)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = CustomUnofficialWorldChampion(frame)
	unofficialWorldChampion:setWidgetInjector(CustomInjector(unofficialWorldChampion))

	return unofficialWorldChampion:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		--Regional distribution
		table.insert(widgets, String.isNotEmpty(args.region1) and Title{children = 'Regional distribution'} or nil)

		for regionKey, region in Table.iter.pairsByPrefix(args, 'region') do
			Array.appendWith(widgets,
				Cell{name = (args[regionKey .. ' no'] or '') .. ' champions', content = {region}},
				Breakdown{children = {args[regionKey .. ' champions']}}
			)
		end
	end

	return widgets
end

return CustomUnofficialWorldChampion
