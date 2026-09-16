---
-- @Liquipedia
-- page=Module:Features/Squad/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Arguments = Lua.import('Module:Arguments')
local Context = Lua.import('Module:Widget/ComponentContext')
local FnUtil = Lua.import('Module:FnUtil')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local SquadParser = Lua.import('Module:Features/Squad/Lib/Parse')
local SquadColumnAnalyser = Lua.import('Module:Features/Squad/Lib/Columns')
local SquadStore = Lua.import('Module:Features/Squad/Api/Store')
local Table = Lua.import('Module:Table')

local ErrorBoundary = Lua.import('Module:Widget/ErrorBoundary')
local SquadContexts = Lua.import('Module:Features/Squad/Components/Contexts')
local SquadDisplay = Lua.import('Module:Features/Squad/Components/Container')
local SquadHeader = Lua.import('Module:Features/Squad/Components/Header')
local SquadPlayerDisplay = Lua.import('Module:Features/Squad/Components/Player')
local Table2 = Lua.import('Module:Widget/Table2/All')
local LegacyAdaptor = Lua.import('Module:Features/Squad/LegacyAdaptor')
local AutoSquad = Lua.import('Module:Features/Squad/Auto')
local SquadTransferHistory = Lua.import('Module:Features/Squad/Api/TransferHistory')


local SquadController = {}

---@param squadData SquadWrapper
---@param adjustLpdb function?
---@return Renderable
function SquadController.execute(squadData, adjustLpdb)
	local squadPlayers = Array.map(squadData.players, function(player)
		return SquadParser.readSquadPersonArgs(Table.merge(
			player,
			{status = squadData.squadStatus, type = squadData.squadType}
		))
	end)

	if adjustLpdb then
		Array.forEach(squadPlayers, FnUtil.curry(adjustLpdb, squadData))
	end

	Array.forEach(squadPlayers, SquadStore.storeSquadPerson)

	local squadTable = Context.Provider{
		def = SquadContexts.ColumnVisibility,
		value = SquadColumnAnalyser.analyzeColumnVisibility(squadPlayers, squadData.squadStatus),
		children = {
			SquadDisplay{
				status = squadData.squadStatus,
				title = squadData.title,
				type = squadData.squadType,
				header = SquadHeader{status = squadData.squadStatus},
				children = Array.map(squadPlayers, function(squadPlayer)
					return ErrorBoundary{
						children = SquadPlayerDisplay{squadPlayer = squadPlayer},
						fallback = function()
							return Table2.Row{
								Table2.Cell{colspan = 100, children = 'Error loading player ' .. (squadPlayer.id or '')},
							}
						end,
					}
				end)
			}
		}
	}
	if not Info.config.squads.hasPosition then
		return squadTable
	end
	return Context.Provider{def = SquadContexts.RoleTitle, value = 'Position', children = {squadTable}}
end

---@param frame Frame
---@return Renderable
function SquadController.run(frame, adjustLpdb)
	if not Info.config.squads.allowManual then
		error('This wiki does not use manual squad tables')
	end

	local args = Arguments.getArgs(frame)
	local squadData = SquadParser.readWrapperArgs(args)
	return SquadController.execute(squadData, adjustLpdb)
end

---@deprecated
---@param players table[]
---@param squadStatus SquadStatus
---@param squadType SquadType
---@param customTitle string?
---@return Renderable
function SquadController.runAuto(players, squadStatus, squadType, customTitle, adjustLpdb)
	players = Array.map(players, SquadParser.convertAutoParameters)
	local squadData = SquadParser.createWrapperData(players, squadType, squadStatus, customTitle)
	return SquadController.execute(squadData, adjustLpdb)
end

---@param frame Frame
---@return Renderable?
function SquadController.runNewAuto(frame)
	local args = Arguments.getArgs(frame)

	if not Info.config.squads.standardizedAuto then
		return LegacyAdaptor.adapt(args)
	end

	local config = AutoSquad._parseConfig(args)
	local manualPlayers, enrichmentInfo = AutoSquad._readManualRowInput(args, config)
	local playersTeamHistory = SquadTransferHistory.forTeam(config.team, config.teams)
	local entries = AutoSquad._selectEntries(playersTeamHistory, manualPlayers, config)
	Array.forEach(entries, FnUtil.curry(AutoSquad._enrichEntry, enrichmentInfo))

	if Logic.isEmpty(entries) then
		return
	end

	return AutoSquad.display(config, entries)
end

return SquadController
