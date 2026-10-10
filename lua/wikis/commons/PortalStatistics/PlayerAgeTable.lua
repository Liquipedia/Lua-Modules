---
-- @Liquipedia
-- page=Module:PortalStatistics/PlayerAgeTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local Lpdb = Lua.import('Module:Lpdb')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local TableWidgets = Lua.import('Module:Widget/Table2/All')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local LANG = mw.getContentLanguage()

local StatisticsPortal = {}


---@param args table?
---@return Renderable
function StatisticsPortal.playerAgeTable(args)
	args = args or {}
	args.earnings = tonumber(args.earnings) or 500
	args.limit = tonumber(args.limit) or 20
	args.order = 'birthdate ' .. (args.order or 'desc')

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('birthdate'), Comparator.neq, '')}
		:add{ConditionNode(ColumnName('birthdate'), Comparator.neq, DateExt.defaultDate)}
		:add{ConditionNode(ColumnName('deathdate'), Comparator.eq, DateExt.defaultDate)}
		:add{ConditionNode(ColumnName('earnings'), Comparator.gt, args.earnings)}

	if Logic.readBool(args.isActive) then
		conditions:add{ConditionNode(ColumnName('status'), Comparator.eq, 'Active')}
	end

	if Logic.readBool(args.playersOnly) then
		local typeConditions = ConditionTree(BooleanOperator.any)
		typeConditions:add{
			ConditionNode(ColumnName('type'), Comparator.eq, 'player'),
			ConditionNode(ColumnName('type'), Comparator.eq, 'Player'),
		}
		conditions:add{typeConditions}
	end

	conditions:add(ConditionUtil.anyOf(
		ColumnName('nationality'),
		Array.map(Array.parseCommaSeparatedString(args.nationality), function (nationality)
			return Flags.CountryName{flag = nationality}
		end)
	))

	local playerData = StatisticsPortal._getPlayers(args.limit, conditions:toString(), args.order)

	local tableHeader = TableWidgets.Row{
		children = {
			TableWidgets.CellHeader{unsortable = true, children = 'ID'},
			TableWidgets.CellHeader{children = 'Age'}
		}
	}

	local tableRow = Array.map(playerData, function(player)
		local birthdate = DateExt.readTimestamp(player.birthdate) --[[@as integer]]
		local ageInSeconds = os.difftime(DateExt.getCurrentTimestamp(), birthdate)

		return TableWidgets.Row{children = {
			TableWidgets.Cell{children = OpponentDisplay.BlockOpponent{
				opponent = StatisticsPortal._toOpponent(player),
				showPlayerTeam = true,
			}},
			TableWidgets.Cell{children = LANG:formatDuration(ageInSeconds, {'years', 'days'})}
		}}
	end)

	return TableWidgets.Table{
		sortable = true,
		css = {['margin-left'] = '0px', ['margin-right'] = 'auto'},
		children = {
			TableWidgets.TableHeader{children = tableHeader},
			TableWidgets.TableBody{children = tableRow}
		}
	}
end


--[[
Section: Query Functions
]]--

---Executes a given LPDB query using Lpdb.executeMassQuery

---@param tableName string Name of the table
---@param parameters table Query parameters
---@return table
function StatisticsPortal._massQuery(tableName, parameters)
	local data = {}

	Lpdb.executeMassQuery(tableName, parameters, function (item)
		table.insert(data, item)
	end, parameters.limit)

	return data
end

---@param limit number?
---@param addConditions string|AbstractConditionNode?
---@param addOrder string?
---@return table
function StatisticsPortal._getPlayers(limit, addConditions, addOrder)
	return StatisticsPortal._massQuery('player', {
		query = 'pagename, id, nationality, earnings, birthdate, team, earningsbyyear',
		conditions = addConditions and tostring(addConditions) or '',
		order = addOrder,
		limit = limit,
	})
end

---@param player table
---@return table
function StatisticsPortal._toOpponent(player)
	return {
		type = Opponent.solo,
		players = {{
			pageName = player.pagename,
			displayName = player.id,
			flag = player.nationality,
			team = String.isNotEmpty(player.team) and player.team or nil,
		}},
	}
end

return Class.export(StatisticsPortal, {exports = {'playerAgeTable'}})
