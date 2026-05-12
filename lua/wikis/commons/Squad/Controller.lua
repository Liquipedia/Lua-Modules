---
-- @Liquipedia
-- page=Module:Squad/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Arguments = Lua.import('Module:Arguments')
local Context = Lua.import('Module:Widget/ComponentContext')
local FnUtil = Lua.import('Module:FnUtil')
local Info = Lua.import('Module:Info', {loadData = true})
local SquadUtils = Lua.import('Module:Squad/Utils')
local Table = Lua.import('Module:Table')

local SquadContexts = Lua.import('Module:Widget/Contexts/Squad')
local ErrorBoundary = Lua.import('Module:Widget/ErrorBoundary')
local SquadDisplay = Lua.import('Module:Widget/Squad/Container')
local SquadHeader = Lua.import('Module:Widget/Squad/Header')
local SquadPlayerDisplay = Lua.import('Module:Widget/Squad/Player')
local Table2 = Lua.import('Module:Widget/Table2/All')

local SquadController = {}

---@param squadData SquadWrapper
---@param adjustLpdb function?
---@return Component
function SquadController.execute(squadData, adjustLpdb)
	local squadPlayers = Array.map(squadData.players, function(player)
		return SquadUtils.readSquadPersonArgs(Table.merge(
			player,
			{status = squadData.squadStatus, type = squadData.squadType}
		))
	end)

	if adjustLpdb then
		Array.forEach(squadPlayers, FnUtil.curry(adjustLpdb, squadData))
	end

	Array.forEach(squadPlayers, function (squadPlayer)
		squadPlayer:save()
	end)

	local squadTable = Context.Provider{
		def = SquadContexts.ColumnVisibility,
		value = SquadUtils.analyzeColumnVisibility(squadPlayers, squadData.squadStatus),
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
---@return Widget
function SquadController.run(frame, adjustLpdb)
	if not Info.config.squads.allowManual then
		error('This wiki does not use manual squad tables')
	end

	local args = Arguments.getArgs(frame)
	local squadData = SquadUtils.readWrapperArgs(args)
	return SquadController.execute(squadData, adjustLpdb)
end

---@param players table[]
---@param squadStatus SquadStatus
---@param squadType SquadType
---@param customTitle string?
---@return Widget
function SquadController.runAuto(players, squadStatus, squadType, customTitle, adjustLpdb)
	local mappedPlayers = Array.map(players, SquadUtils.convertAutoParameters)
	local squadData = SquadUtils.createWrapperData(mappedPlayers, squadType, squadStatus, customTitle)
	return SquadController.execute(squadData, adjustLpdb)
end

return SquadController
