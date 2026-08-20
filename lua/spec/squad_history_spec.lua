--- Triple Comment to Enable our LLS Plugin
--[[
Unit tests for Module:Features/Squad/Lib/History.

This is the payoff of step 1.4 of the bulletproof-lua plan (docs/bulletproof-lua.md): the transfer
history logic used to be tangled with LPDB queries inside Squad/Auto, so it could only be tested
through the whole squad table. It is pure now, so it can be tested directly, with no mocks at all.

The end to end behaviour of the same logic stays covered by squad_auto_spec.lua.
]]

local SquadHistory = require('Module:Features/Squad/Lib/History')
local SquadTypes = require('Module:Features/Squad/Types')
local Table = require('Module:Table')

local TransferType = SquadTypes.TransferType
local SquadStatus = SquadTypes.SquadStatus

local TEAM = 'mouz 2021'
local OTHER_TEAM = 'team liquid 2024'
local TEAMS = {'mousesports orig', TEAM}

---Builds a transfer record. `extradata` is merged rather than replaced.
---@param props table?
---@return table
local function transfer(props)
	props = Table.copy(props or {})
	local extradata = Table.extract(props, 'extradata') or {}
	local record = Table.merge({
		player = 'Alice',
		nationality = 'se',
		date = '2022-01-01',
		fromteamtemplate = '',
		toteamtemplate = '',
		role1 = '',
		role2 = '',
		wholeteam = 0,
		reference = {},
	}, props)
	record.extradata = Table.merge({displayname = record.player}, extradata)
	return record
end

---Reads a transfer that is expected to be relevant to the team.
---@param record table
---@return TeamHistoryEntry
local function fromTransfer(record)
	local result = SquadHistory.fromTransfer(record, TEAMS)
	assert(result, 'expected the transfer to be relevant to the team')
	return result
end

---@param props table?
---@return TeamHistoryEntry
local function entry(props)
	return Table.merge({
		type = TransferType.JOIN,
		pagename = 'Alice',
		displayname = 'Alice',
		date = '2022-01-01',
	}, props or {})
end

describe('Squad history', function()
	describe('fromTransfer', function()
		it('reads a transfer into the team as a join', function()
			local result = fromTransfer(transfer{
				toteamtemplate = TEAM,
				role2 = 'Standin',
				nationality = 'se',
				extradata = {displayname = 'AliceTag', displaydate = '2022-01-??', position = 'Mid'},
			})

			assert.are_equal(TransferType.JOIN, result.type)
			assert.are_equal('Alice', result.pagename)
			assert.are_equal('AliceTag', result.displayname)
			assert.are_equal('se', result.flag)
			assert.are_equal('2022-01-01', result.date)
			assert.are_equal('2022-01-??', result.dateDisplay)
			assert.are_equal('Mid', result.position)
			assert.are_equal(TEAM, result.toTeam)
			assert.are_equal('Standin', result.toRole)
			assert.is_nil(result.fromTeam)
			assert.is_nil(result.fromRole)
			assert.is_false(result.wholeTeam)
		end)

		it('reads a transfer away from the team as a leave', function()
			local result = fromTransfer(transfer{
				fromteamtemplate = TEAM,
				role1 = 'Standin',
				toteamtemplate = OTHER_TEAM,
				role2 = 'Coach',
			})

			assert.are_equal(TransferType.LEAVE, result.type)
			assert.are_equal(TEAM, result.fromTeam)
			assert.are_equal('Standin', result.fromRole)
			-- the team the person went to is carried along so it can be shown as the next team
			assert.are_equal(OTHER_TEAM, result.toTeam)
			assert.are_equal('Coach', result.toRole)
		end)

		it('reads a transfer within the team as a change', function()
			local result = fromTransfer(transfer{
				fromteamtemplate = TEAM,
				role1 = 'Standin',
				toteamtemplate = TEAM,
				role2 = 'Captain',
			})

			assert.are_equal(TransferType.CHANGE, result.type)
			assert.are_equal('Standin', result.fromRole)
			assert.are_equal('Captain', result.toRole)
		end)

		it('matches any of the historical templates of the team', function()
			local result = fromTransfer(transfer{toteamtemplate = 'mousesports orig'})
			assert.are_equal(TransferType.JOIN, result.type)
			assert.are_equal('mousesports orig', result.toTeam)
		end)

		it('follows the team through the secondary team fields', function()
			local result = fromTransfer(transfer{
				toteamtemplate = OTHER_TEAM,
				role2 = 'Coach',
				extradata = {toteamsectemplate = TEAM, role2sec = 'Standin'},
			})

			assert.are_equal(TransferType.JOIN, result.type)
			assert.are_equal(TEAM, result.toTeam)
			-- the role on the secondary team is the relevant one
			assert.are_equal('Standin', result.toRole)
		end)

		it('prefers the main team over the secondary one', function()
			local result = fromTransfer(transfer{
				toteamtemplate = TEAM,
				role2 = 'Captain',
				extradata = {toteamsectemplate = 'mousesports orig', role2sec = 'Standin'},
			})
			assert.are_equal('Captain', result.toRole)
		end)

		it('carries the next team from the secondary field when the person left it', function()
			local result = fromTransfer(transfer{
				fromteamtemplate = OTHER_TEAM,
				toteamtemplate = 'team liquid 2023',
				role2 = 'Coach',
				extradata = {
					fromteamsectemplate = TEAM,
					toteamsectemplate = 'team liquid 2023',
					role1sec = 'Standin',
					role2sec = 'Captain',
				},
			})

			assert.are_equal(TransferType.LEAVE, result.type)
			assert.are_equal(TEAM, result.fromTeam)
			assert.are_equal('Standin', result.fromRole)
			-- the next team is taken from the secondary side too, not from the main one
			assert.are_equal('team liquid 2023', result.toTeam)
			assert.are_equal('Captain', result.toRole)
		end)

		it('carries nothing along when the person left the team for nowhere', function()
			local result = fromTransfer(transfer{
				fromteamtemplate = OTHER_TEAM,
				toteamtemplate = '',
				extradata = {fromteamsectemplate = TEAM, toteamsectemplate = '', role1sec = 'Standin'},
			})

			assert.are_equal(TransferType.LEAVE, result.type)
			assert.is_nil(result.toTeam)
			assert.is_nil(result.toRole)
		end)

		it('skips a transfer that changes nothing for the team', function()
			-- the person moved between two other teams while keeping the same role here
			assert.is_nil(SquadHistory.fromTransfer(transfer{
				fromteamtemplate = OTHER_TEAM,
				toteamtemplate = 'team liquid 2023',
				extradata = {
					fromteamsectemplate = TEAM,
					toteamsectemplate = TEAM,
					role1sec = 'Standin',
					role2sec = 'Standin',
				},
			}, TEAMS))
		end)

		it('keeps a transfer that only changes the role within the team', function()
			local result = fromTransfer(transfer{
				fromteamtemplate = TEAM,
				role1 = 'Standin',
				toteamtemplate = TEAM,
				role2 = 'Captain',
			})
			assert.is_truthy(result)
		end)

		it('skips a transfer that does not involve the team at all', function()
			assert.is_nil(SquadHistory.fromTransfer(transfer{
				fromteamtemplate = OTHER_TEAM,
				toteamtemplate = OTHER_TEAM,
			}, TEAMS))
		end)

		it('reads the whole team flag', function()
			assert.is_true(fromTransfer(transfer{toteamtemplate = TEAM, wholeteam = 1}).wholeTeam)
		end)

		it('copes with a record that has no extradata', function()
			local record = transfer{toteamtemplate = TEAM}
			record.extradata = nil
			assert.are_equal(TransferType.JOIN, fromTransfer(record).type)
		end)
	end)

	describe('fromTransfers', function()
		it('groups the entries per person', function()
			local history = SquadHistory.fromTransfers({
				transfer{player = 'Alice', toteamtemplate = TEAM, date = '2021-01-01'},
				transfer{player = 'Bob', toteamtemplate = TEAM, date = '2021-02-01'},
				transfer{player = 'Alice', fromteamtemplate = TEAM, date = '2022-01-01'},
			}, TEAMS)

			assert.are_equal(2, #history.Alice)
			assert.are_equal(1, #history.Bob)
			assert.are_equal('2021-01-01', history.Alice[1].date)
			assert.are_equal('2022-01-01', history.Alice[2].date)
		end)

		it('keeps a person whose every transfer was skipped, with an empty history', function()
			local history = SquadHistory.fromTransfers({
				transfer{player = 'Alice', fromteamtemplate = OTHER_TEAM, toteamtemplate = OTHER_TEAM},
			}, TEAMS)

			assert.are_same({Alice = {}}, history)
		end)

		it('returns an empty table when there are no transfers', function()
			assert.are_same({}, SquadHistory.fromTransfers({}, TEAMS))
		end)
	end)

	describe('selectStints for an active squad', function()
		it('takes the most recent transfer when it put the person on the team', function()
			local join = entry{type = TransferType.JOIN}
			local selection = SquadHistory.selectStints({join}, SquadStatus.ACTIVE)

			assert.are_equal(1, #selection.stints)
			assert.are_equal(join, selection.stints[1].joinEntry)
			assert.is_nil(selection.stints[1].inactiveEntry)
			assert.is_nil(selection.stints[1].leaveEntry)
			assert.is_false(selection.hasInactiveEntry)
			assert.are_same({}, selection.warnings)
		end)

		it('takes a role change as the start of the current stint', function()
			local join = entry{type = TransferType.JOIN, date = '2021-01-01'}
			local roleChange = entry{type = TransferType.CHANGE, date = '2022-01-01', toRole = 'Captain'}
			local selection = SquadHistory.selectStints({join, roleChange}, SquadStatus.ACTIVE)

			assert.are_equal(roleChange, selection.stints[1].joinEntry)
		end)

		it('takes nobody whose last transfer was a leave', function()
			local selection = SquadHistory.selectStints(
				{entry{type = TransferType.JOIN}, entry{type = TransferType.LEAVE}},
				SquadStatus.ACTIVE
			)
			assert.are_same({}, selection.stints)
		end)

		it('takes nobody whose last transfer made them inactive', function()
			local selection = SquadHistory.selectStints(
				{entry{type = TransferType.JOIN}, entry{type = TransferType.CHANGE, toRole = 'Inactive'}},
				SquadStatus.ACTIVE
			)
			assert.are_same({}, selection.stints)
		end)
	end)

	describe('selectStints for an inactive squad', function()
		it('pairs the transfer that made someone inactive with the one before it', function()
			local join = entry{type = TransferType.JOIN, date = '2021-01-01'}
			local inactive = entry{type = TransferType.CHANGE, date = '2022-01-01', toRole = 'Inactive'}
			local selection = SquadHistory.selectStints({join, inactive}, SquadStatus.INACTIVE)

			assert.are_equal(1, #selection.stints)
			assert.are_equal(join, selection.stints[1].joinEntry)
			assert.are_equal(inactive, selection.stints[1].inactiveEntry)
			assert.is_nil(selection.stints[1].leaveEntry)
			-- the table is already inactive, so nothing has to switch it over
			assert.is_false(selection.hasInactiveEntry)
		end)

		it('takes nobody who is still active', function()
			assert.are_same({}, SquadHistory.selectStints({entry{}}, SquadStatus.INACTIVE).stints)
		end)

		it('takes nobody whose inactive transfer has nothing before it', function()
			local selection = SquadHistory.selectStints(
				{entry{type = TransferType.CHANGE, toRole = 'Inactive'}},
				SquadStatus.INACTIVE
			)
			assert.are_same({}, selection.stints)
		end)

		it('takes nobody whose last transfer was a leave', function()
			local selection = SquadHistory.selectStints(
				{entry{type = TransferType.JOIN}, entry{type = TransferType.LEAVE}},
				SquadStatus.INACTIVE
			)
			assert.are_same({}, selection.stints)
		end)
	end)

	describe('selectStints for a former squad', function()
		it('pairs a join with the leave that follows it', function()
			local join = entry{type = TransferType.JOIN, date = '2021-01-01'}
			local leave = entry{type = TransferType.LEAVE, date = '2022-01-01'}
			local selection = SquadHistory.selectStints({join, leave}, SquadStatus.FORMER)

			assert.are_equal(1, #selection.stints)
			assert.are_same({joinEntry = join, inactiveEntry = nil, leaveEntry = leave}, selection.stints[1])
			assert.is_false(selection.hasInactiveEntry)
		end)

		it('splits a role change into two stints, the change ending one and starting the next', function()
			local join = entry{type = TransferType.JOIN, date = '2021-01-01'}
			local roleChange = entry{type = TransferType.CHANGE, date = '2022-01-01', toRole = 'Captain'}
			local leave = entry{type = TransferType.LEAVE, date = '2023-01-01'}
			local selection = SquadHistory.selectStints({join, roleChange, leave}, SquadStatus.FORMER)

			assert.are_equal(2, #selection.stints)
			assert.are_equal(join, selection.stints[1].joinEntry)
			assert.are_equal(roleChange, selection.stints[1].leaveEntry)
			assert.are_equal(roleChange, selection.stints[2].joinEntry)
			assert.are_equal(leave, selection.stints[2].leaveEntry)
		end)

		it('folds a stint that went inactive before it ended into one stint', function()
			local join = entry{type = TransferType.JOIN, date = '2021-01-01'}
			local inactive = entry{type = TransferType.CHANGE, date = '2022-01-01', toRole = 'Inactive'}
			local leave = entry{type = TransferType.LEAVE, date = '2023-01-01'}
			local selection = SquadHistory.selectStints({join, inactive, leave}, SquadStatus.FORMER)

			assert.are_equal(1, #selection.stints)
			assert.are_same({joinEntry = join, inactiveEntry = inactive, leaveEntry = leave}, selection.stints[1])
			-- which is what tells the caller to show the Inactive Date column
			assert.is_true(selection.hasInactiveEntry)
		end)

		it('reports the inactive transfer even when the stint never ended', function()
			local selection = SquadHistory.selectStints({
				entry{type = TransferType.JOIN, date = '2021-01-01'},
				entry{type = TransferType.CHANGE, date = '2022-01-01', toRole = 'Inactive'},
			}, SquadStatus.FORMER)

			assert.are_same({}, selection.stints)
			assert.is_true(selection.hasInactiveEntry)
		end)

		it('leaves an unfinished stint out', function()
			local selection = SquadHistory.selectStints({entry{type = TransferType.JOIN}}, SquadStatus.FORMER)
			assert.are_same({}, selection.stints)
			assert.are_same({}, selection.warnings)
		end)

		it('skips a duplicate join and reports it', function()
			local duplicate = entry{type = TransferType.JOIN, date = '2021-06-01'}
			local selection = SquadHistory.selectStints({
				entry{type = TransferType.JOIN, date = '2021-01-01'},
				duplicate,
				entry{type = TransferType.LEAVE, date = '2022-01-01'},
			}, SquadStatus.FORMER)

			assert.are_equal(1, #selection.stints)
			assert.are_equal('2021-01-01', selection.stints[1].joinEntry.date)
			assert.are_same({{reason = 'Invalid entry: Duplicate JOIN. Skipping', entry = duplicate}},
				selection.warnings)
		end)

		it('skips a leave without a join and reports it', function()
			local orphan = entry{type = TransferType.LEAVE, date = '2022-01-01'}
			local selection = SquadHistory.selectStints({orphan}, SquadStatus.FORMER)

			assert.are_same({}, selection.stints)
			assert.are_same({{reason = 'Invalid entry: Missing previous JOIN. Skipping', entry = orphan}},
				selection.warnings)
		end)

		it('recovers after an invalid entry', function()
			local selection = SquadHistory.selectStints({
				entry{type = TransferType.LEAVE, date = '2020-01-01'},
				entry{type = TransferType.JOIN, date = '2021-01-01'},
				entry{type = TransferType.LEAVE, date = '2022-01-01'},
			}, SquadStatus.FORMER)

			assert.are_equal(1, #selection.stints)
			assert.are_equal(1, #selection.warnings)
		end)

		it('handles a former inactive table the same way as a former one', function()
			local join = entry{type = TransferType.JOIN, date = '2021-01-01'}
			local leave = entry{type = TransferType.LEAVE, date = '2022-01-01'}
			assert.are_same(
				SquadHistory.selectStints({join, leave}, SquadStatus.FORMER),
				SquadHistory.selectStints({join, leave}, SquadStatus.FORMER_INACTIVE)
			)
		end)
	end)

	describe('selectStints edge cases', function()
		it('takes nobody for an unknown status', function()
			local selection = SquadHistory.selectStints({entry{}}, nil)
			assert.are_same({stints = {}, warnings = {}, hasInactiveEntry = false}, selection)
		end)

		it('handles an empty history for the statuses that walk it', function()
			assert.are_same({}, SquadHistory.selectStints({}, SquadStatus.FORMER).stints)
			assert.are_same({}, SquadHistory.selectStints({}, SquadStatus.INACTIVE).stints)
		end)

		it('does not error on an empty history for an active squad', function()
			-- fromTransfers can produce an empty history for someone whose transfers were all skipped
			assert.are_same({}, SquadHistory.selectStints({}, SquadStatus.ACTIVE).stints)
		end)
	end)
end)
