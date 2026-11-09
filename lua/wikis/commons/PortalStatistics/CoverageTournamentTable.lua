---
-- @Liquipedia
-- page=Module:PortalStatistics/CoverageTournamentTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Count = Lua.import('Module:Count')
local Info = Lua.import('Module:Info', {loadData = true})
local Operator = Lua.import('Module:Operator')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Custom')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Util = Lua.import('Module:PortalStatistics/Util')

local LANG = mw.getContentLanguage()
local DEFAULT_TIERTYPES = {'', 'Weekly', 'Monthly'}

local CoverageTournamentTable = {}


---@param args table?
---@return Renderable
function CoverageTournamentTable.coverageTournamentTable(args)
	args = args or {}
	args.multiGame = Logic.readBool(args.multiGame)
	args.customGames = Util.isTableOrSplitOrDefault(args.customGames, Util.GAMES)
	args.customTiers = Util.isTableOrSplitOrDefault(args.customTiers)
	args.customTiers = args.customTiers and Array.map(args.customTiers, function(tier) return tonumber(tier) end)
	args.includeTierTypes = Util.isTableOrSplitOrDefault(args.includeTierTypes, DEFAULT_TIERTYPES)
	args.showTierTypes = Util.isTableOrSplitOrDefault(args.showTierTypes, {})
	args.filterByStatus = Logic.readBool(args.filterByStatus) or false

	local tableRow = WidgetUtil.collect(
		args.multiGame and Array.map(args.customGames, function(game)
			return CoverageTournamentTable._coverageTournamentTableRow(args, {
				game = game,
				year = args.year,
				filterByStatus = args.filterByStatus
			})
		end) or nil,
		CoverageTournamentTable._coverageTournamentTableRow(args, {
			year = args.year,
			filterByStatus = args.filterByStatus
		})
	)

	return TableWidgets.Table{
		caption = args.tournamentTableTitle or 'Tournaments Covered',
		children = {
			TableWidgets.TableHeader{children = CoverageTournamentTable._coverageTournamentTableHeader(args)},
			TableWidgets.TableBody{children = tableRow}
		}
	}
end

---@param args table
---@param parameters table
---@return Renderable
function CoverageTournamentTable._coverageTournamentTableRow(args, parameters)
	local isHeaderRow = Logic.readBool(args.multiGame) and not parameters.game
	local CellComponent = isHeaderRow and TableWidgets.CellHeader or TableWidgets.Cell
	local runningTally = 0

	local gameCell = Logic.readBool(args.multiGame)
		and Util.returnGameCell(args, parameters, isHeaderRow)
		or nil

	local countData = Count.tournamentsByTier(parameters)

	local tierCells = {}
	for rowIndex, rowValue in Tier.iterate('tiers') do
		if String.isNotEmpty(rowValue.value) and tonumber(rowValue.value) > 0 then
			if not args.customTiers or Array.any(Array.extractValues(args.customTiers), function(value)
				return value == rowIndex
			end) then
				local tierData = countData[rowValue.value] or {}
				local tournamentCount = 0
				Array.forEach(args.includeTierTypes,
					function(tiertype, _)
						local typeCount = tonumber(Table.extract(tierData, tiertype)) or 0
						tournamentCount = tournamentCount + typeCount
					end
				)
				runningTally = runningTally + tournamentCount
				table.insert(tierCells, CellComponent{align = 'right', children = LANG:formatNum(tournamentCount)})
			end
		end
	end

	local tierTypeCells = Array.map(args.showTierTypes, function(tierTypeValue)
		local _, tierTypeData = Tier.raw(nil, tierTypeValue)
		if tierTypeData then
			local count = Array.reduce(
				Array.map(Array.extractValues(countData), function(typeCounts)
					return Table.extract(typeCounts, tierTypeValue) or 0
				end),
				Operator.add, 0
			)
			runningTally = runningTally + count
			return CellComponent{align = 'right', children = LANG:formatNum(count)}
		end
	end)

	local otherCell
	if String.isNotEmpty(args.showOther) then
		local countOther = Array.reduce(
			Array.flatMap(Array.extractValues(countData), function(typeCounts)
				return Table.isNotEmpty(typeCounts) and Array.extractValues(typeCounts) or 0
			end
			), Operator.add, 0) --[[@as number]]
		runningTally = runningTally + countOther
		otherCell = CellComponent{align = 'right', children = LANG:formatNum(countOther)}
	end

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			gameCell,
			tierCells,
			tierTypeCells,
			otherCell,
			CellComponent{align = 'right', children = LANG:formatNum(runningTally)}
		)
	}
end

---@param args table
---@return Renderable
function CoverageTournamentTable._coverageTournamentTableHeader(args)
	local tierHeaderCells = {}
	for headerIndex, headerValue in Tier.iterate('tiers') do
		if String.isNotEmpty(headerValue.value) and tonumber(headerValue.value) > 0 then
			if not args.customTiers or Array.any(Array.extractValues(args.customTiers), function(value)
				return value == headerIndex
			end) then
				table.insert(tierHeaderCells, TableWidgets.CellHeader{
					children = Tier.displaySingle(headerValue, {link = true})
				})
			end
		end
	end

	local tierTypeHeaderCells = {}
	for _, tierTypeValue in ipairs(args.showTierTypes) do
		local _, tierTypeData = Tier.raw(nil, tierTypeValue)
		if tierTypeData then
			table.insert(tierTypeHeaderCells, TableWidgets.CellHeader{
				children = Tier.displaySingle(tierTypeData, {link = true, short = true})
			})
		end
	end

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			Logic.readBool(args.multiGame) and TableWidgets.CellHeader{children = 'Game'} or nil,
			tierHeaderCells,
			tierTypeHeaderCells,
			String.isNotEmpty(args.showOther) and TableWidgets.CellHeader{
				children = Abbreviation.make{text = 'Other',
					title = 'Includes otherwise unlisted tournaments (e.g. with tiertypes, misc.)'}
			} or nil,
			TableWidgets.CellHeader{children = 'Total'}
		)
	}
end

--[[
Section: Utility Functions
]]--

return Class.export(CoverageTournamentTable, {exports = {'coverageTournamentTable'}})
