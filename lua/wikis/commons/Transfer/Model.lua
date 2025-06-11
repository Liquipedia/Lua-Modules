---
-- @Liquipedia
-- page=Module:Transfer/Model
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local Team = Lua.import('Module:Team')

local ROLE_CLEAN = Lua.requireIfExists('Module:TeamHistoryAuto/cleanRole', {loadData = true})

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local LOAN = 'Loan'

local Transfer = {}

---@class TransferSpan
---@field team string
---@field role string
---@field position string
---@field joinDate string|number
---@field joinDateDisplay string
---@field leaveDate string|number?
---@field leaveDateDisplay string?
---@field reference {join: table?, leave: table?}

---@param config {player: string, specialRoles: string[]?}
---@return TransferSpan[]
function Transfer.getTeamHistoryForPerson(config)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDate),
		ConditionNode(ColumnName('player'), Comparator.eq, config.player),
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('toteam'), Comparator.neq, ''),
			Array.map(config.specialRoles or {}, function(role)
				return ConditionNode(ColumnName('role2'), Comparator.eq, role)
			end),
		},
	}

	local records = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = conditions:toString(),
		order = 'date asc',
		limit = 5000,
		query = 'pagename, fromteam, toteam, role1, role2, date, extradata, reference'
	})

	local transferList = {}
	Array.forEach(records, function(record)
		Array.appendWith(transferList, unpack(Transfer._processTransfer(record)))
	end)

	if ROLE_CLEAN then
		Array.forEach(transferList, function(transfer)
			transfer.role = ROLE_CLEAN[(transfer.role or ''):lower()]
		end)
	end

	transferList = Array.map(transferList, FnUtil.curry(Transfer._completeTransfer, config))

	-- Sort table by joinDate/leaveDate
	table.sort(transferList, function(transfer1, transfer2)
		if transfer1.joinDate == transfer2.joinDate then
			if transfer1.role == LOAN and transfer2.role ~= LOAN then
				return false
			elseif transfer2.role == LOAN and transfer1.role ~= LOAN then
				return true
			end

			return (transfer1.leaveDate or '') < (transfer2.leaveDate or '')
		end

		return transfer1.joinDate < transfer2.joinDate
	end)

	return transferList
end

---@param transfer transfer
---@return TransferSpan[]
function Transfer._processTransfer(transfer)
	local extraData = transfer.extradata
	local transferDate = DateExt.toYmdInUtc(transfer.date)

	if Logic.isEmpty(extraData.toteamsec) then
		-- transfer does not include multiple teams that were joined
		if transfer.toteam == extraData.fromteamsec and transfer.role2 == extraData.role1sec then
			-- the joined team & role was already set before (as 2nd team + role)
			return {}
		end
		-- classic transfer
		return {{
			team = transfer.toteam,
			role = transfer.role2,
			position = extraData.icon2,
			joinDate = transferDate,
			joinDateDisplay = extraData.displaydate or transferDate,
			reference = {join = transfer.reference},
		}}
	end

	-- case: transfer includes multiple teams (Tl:Transfer_row |team2_2, |role2_2)
	local transfers = {}

	if (extraData.toteamsec ~= transfer.fromteam or extraData.role2sec ~= transfer.role1) and
		(extraData.toteamsec ~= extraData.fromteamsec or extraData.role2sec ~= extraData.role1sec) then
		-- secondary transfer
		table.insert(transfers, {
			team = extraData.toteamsec,
			role = extraData.role2sec,
			position = extraData.icon2,
			joinDate = transferDate,
			joinDateDisplay = extraData.displaydate or transferDate,
			reference = {join = transfer.reference},
		})
	end

	if (transfer.toteam ~= transfer.fromteam or transfer.role2 ~= transfer.role1) and
		(transfer.toteam ~= extraData.fromteamsec or transfer.role2 ~= extraData.role1sec) then
		-- primary transfer
		table.insert(transfers, {
			team = transfer.toteam,
			role = transfer.role2,
			position = extraData.icon2,
			joinDate = transferDate,
			joinDateDisplay = extraData.displaydate or transferDate,
			reference = {join = transfer.reference},
		})
	end

	return transfers
end

---@param config {player: string, specialRoles: string[]?}
---@param transfer TransferSpan
---@return TransferSpan
function Transfer._completeTransfer(config, transfer)
	local leaveTransfers = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = Transfer._buildConditionsForLeaveTransfer(config, transfer),
		order = 'date asc',
		query = 'toteam, role2, date, extradata, reference'
	})

	local hasLeaveDate = function(leaveTransfer)
		local extraData = leaveTransfer.extradata

		return (
			extraData.toteamsec ~= transfer.team or
			extraData.role2sec ~= (transfer.role or '')
		) and (
			leaveTransfer.toteam ~= transfer.team or
			leaveTransfer.role2 ~= (transfer.role or '') or
			extraData.icon2 ~= transfer.position
		)
	end

	for _, leaveTransfer in ipairs(leaveTransfers) do
		if hasLeaveDate(leaveTransfer) then
			transfer.leaveDate = DateExt.toYmdInUtc(leaveTransfer.date)
			transfer.leaveDateDisplay = leaveTransfer.extradata.dispaydate or transfer.leaveDate
			transfer.reference.leave = leaveTransfer.reference

			return transfer
		end
	end

	return transfer
end

---@param config {player: string, specialRoles: string[]?}
---@param transfer TransferSpan
---@return string
function Transfer._buildConditionsForLeaveTransfer(config, transfer)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.ge, transfer.joinDate),
		ConditionNode(ColumnName('player'), Comparator.eq, config.player),
	}

	local historicalNames = Team.queryHistoricalNames(transfer.team)

	local buildFromConditions = function(teamField, roleField)
		local fromConditions = ConditionTree(BooleanOperator.any):add(Array.map(historicalNames, function(team)
			return ConditionNode(ColumnName(teamField), Comparator.eq, team)
		end))

		if ROLE_CLEAN and not transfer.role then
			return fromConditions
		end

		return ConditionTree(BooleanOperator.all):add{
			fromConditions,
			ConditionNode(ColumnName(roleField), Comparator.eq, transfer.role or ''),
		}
	end

	if Logic.isNotEmpty(historicalNames) then
		conditions:add(ConditionTree(BooleanOperator.any):add{
			buildFromConditions('fromteam', 'role1'),
			buildFromConditions('extradata_fromteamsec', 'extradata_role1sec'),
		})
	elseif Table.includes(config.specialRoles, transfer.role) then
		conditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('role1'), Comparator.eq, transfer.role),
			ConditionNode(ColumnName('role1'), Comparator.eq, transfer.role:lower()),
		})
	end

	return conditions:toString()
end

return Transfer
