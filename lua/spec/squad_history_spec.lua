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

--[[
The transfers below are written as what happened to one person on the team, and fed through
fromTransfers, so every case a test describes is one the real parser can actually produce.
]]
local Transfers = {}

---@param date string
---@param role string?
---@return table
function Transfers.joins(date, role)
	return transfer{date = date, toteamtemplate = TEAM, role2 = role or ''}
end

---@param date string
---@param fromRole string?
---@param toRole string?
---@return table
function Transfers.changesRole(date, fromRole, toRole)
	return transfer{date = date, fromteamtemplate = TEAM, toteamtemplate = TEAM,
		role1 = fromRole or '', role2 = toRole or ''}
end

---Stops playing while still on the team. `role1` stays the playing role, which is how these are
---recorded on the wiki and what keeps the transfer from being skipped as a no-op.
---@param date string
---@param playingRole string?
---@return table
function Transfers.stopsPlaying(date, playingRole)
	return Transfers.changesRole(date, playingRole or 'Standin', 'Inactive')
end

---@param date string
---@param toTeam string?
---@return table
function Transfers.leaves(date, toTeam)
	return transfer{date = date, fromteamtemplate = TEAM, toteamtemplate = toTeam or ''}
end

---The team history these transfers produce for the person they concern.
---@param ... table
---@return TeamHistoryEntry[]
local function historyOf(...)
	return SquadHistory.fromTransfers({...}, TEAMS).Alice or {}
end

---The selection a squad table of this status makes, where a row is expected.
---@param history TeamHistoryEntry[]
---@param squadStatus SquadStatus?
---@return SquadHistorySelection
local function selectionFor(history, squadStatus)
	local selection = SquadHistory.selectStints(history, squadStatus)
	assert(selection, 'expected this history to yield a selection')
	return selection
end

---The rows a squad table of this status would show for the given history.
---@param history TeamHistoryEntry[]
---@param squadStatus SquadStatus?
---@return SquadStint[]
local function rowsFor(history, squadStatus)
	local selection = SquadHistory.selectStints(history, squadStatus)
	return selection and selection.stints or {}
end

---@param historyEntry TeamHistoryEntry?
---@return string
local function dateOf(historyEntry)
	assert(historyEntry, 'expected a transfer to be recorded here')
	return historyEntry.date
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

		it('leaves out a person whose every transfer was skipped', function()
			local history = SquadHistory.fromTransfers({
				transfer{player = 'Alice', fromteamtemplate = OTHER_TEAM, toteamtemplate = OTHER_TEAM},
			}, TEAMS)

			assert.are_same({}, history)
		end)

		it('returns an empty table when there are no transfers', function()
			assert.are_same({}, SquadHistory.fromTransfers({}, TEAMS))
		end)
	end)

	describe('an active squad', function()
		it('shows someone whose latest transfer put them on the team', function()
			local selection = selectionFor(
				historyOf(Transfers.joins('2022-01-01', 'Standin')), SquadStatus.ACTIVE)

			assert.are_equal(1, #selection.stints)
			assert.are_equal('2022-01-01', dateOf(selection.stints[1].joinEntry))
			assert.are_equal('Standin', selection.stints[1].joinEntry.toRole)
			assert.is_nil(selection.stints[1].leaveEntry)
			assert.are_same({}, selection.warnings)
		end)

		it('dates the row from the latest role change rather than the original join', function()
			local selection = selectionFor(historyOf(
				Transfers.joins('2021-01-01', 'Standin'),
				Transfers.changesRole('2022-01-01', 'Standin', 'Captain')
			), SquadStatus.ACTIVE)

			assert.are_equal('2022-01-01', dateOf(selection.stints[1].joinEntry))
			assert.are_equal('Captain', selection.stints[1].joinEntry.toRole)
		end)

		it('leaves out someone who has left the team', function()
			assert.are_same({}, rowsFor(historyOf(
				Transfers.joins('2021-01-01'),
				Transfers.leaves('2022-01-01')
			), SquadStatus.ACTIVE))
		end)

		it('leaves out someone who has stopped playing', function()
			assert.are_same({}, rowsFor(historyOf(
				Transfers.joins('2021-01-01', 'Standin'),
				Transfers.stopsPlaying('2022-01-01')
			), SquadStatus.ACTIVE))
		end)
	end)

	describe('an inactive squad', function()
		it('shows when the person joined and when they stopped playing', function()
			local selection = selectionFor(historyOf(
				Transfers.joins('2021-01-01', 'Standin'),
				Transfers.stopsPlaying('2022-01-01')
			), SquadStatus.INACTIVE)

			assert.are_equal(1, #selection.stints)
			assert.are_equal('2021-01-01', dateOf(selection.stints[1].joinEntry))
			assert.are_equal('2022-01-01', dateOf(selection.stints[1].inactiveEntry))
			assert.is_nil(selection.stints[1].leaveEntry)
		end)

		it('leaves out someone who is still playing', function()
			assert.are_same({}, rowsFor(historyOf(Transfers.joins('2021-01-01')), SquadStatus.INACTIVE))
		end)

		it('leaves out someone who stopped playing without ever having joined', function()
			assert.are_same({}, rowsFor(historyOf(Transfers.stopsPlaying('2022-01-01')), SquadStatus.INACTIVE))
		end)

		it('leaves out someone who has left the team', function()
			assert.are_same({}, rowsFor(historyOf(
				Transfers.joins('2021-01-01'),
				Transfers.leaves('2022-01-01')
			), SquadStatus.INACTIVE))
		end)
	end)

	describe('a former squad', function()
		it('shows one row spanning join to leave', function()
			local selection = selectionFor(historyOf(
				Transfers.joins('2021-01-01'),
				Transfers.leaves('2022-01-01')
			), SquadStatus.FORMER)

			assert.are_equal(1, #selection.stints)
			assert.are_equal('2021-01-01', dateOf(selection.stints[1].joinEntry))
			assert.are_equal('2022-01-01', dateOf(selection.stints[1].leaveEntry))
			assert.is_nil(selection.stints[1].inactiveEntry)
			assert.is_false(selection.hasFormerInactiveEntry)
		end)

		it('gives a changed role its own row, ending the previous one', function()
			local selection = selectionFor(historyOf(
				Transfers.joins('2021-01-01', 'Standin'),
				Transfers.changesRole('2022-01-01', 'Standin', 'Captain'),
				Transfers.leaves('2023-01-01')
			), SquadStatus.FORMER)

			assert.are_equal(2, #selection.stints)
			assert.are_equal('2021-01-01', dateOf(selection.stints[1].joinEntry))
			assert.are_equal('2022-01-01', dateOf(selection.stints[1].leaveEntry))
			assert.are_equal('2022-01-01', dateOf(selection.stints[2].joinEntry))
			assert.are_equal('2023-01-01', dateOf(selection.stints[2].leaveEntry))
		end)

		it('keeps a spell that went inactive as one row, and flags the inactive column', function()
			local selection = selectionFor(historyOf(
				Transfers.joins('2021-01-01', 'Standin'),
				Transfers.stopsPlaying('2022-01-01'),
				Transfers.leaves('2023-01-01')
			), SquadStatus.FORMER)

			assert.are_equal(1, #selection.stints)
			assert.are_equal('2021-01-01', dateOf(selection.stints[1].joinEntry))
			assert.are_equal('2022-01-01', dateOf(selection.stints[1].inactiveEntry))
			assert.are_equal('2023-01-01', dateOf(selection.stints[1].leaveEntry))
			assert.is_true(selection.hasFormerInactiveEntry)
		end)

		it('dates an inactive spell from when the person stopped playing', function()
			-- a second inactive transfer is a role change made while already inactive, so the date
			-- the reader sees stays the day they stopped playing
			local selection = selectionFor(historyOf(
				Transfers.joins('2021-01-01', 'Standin'),
				Transfers.stopsPlaying('2022-01-01'),
				Transfers.stopsPlaying('2022-06-01'),
				Transfers.leaves('2023-01-01')
			), SquadStatus.FORMER)

			assert.are_equal(1, #selection.stints)
			assert.are_equal('2022-01-01', dateOf(selection.stints[1].inactiveEntry))
		end)

		it('dates each inactive spell separately when the person played again in between', function()
			local selection = selectionFor(historyOf(
				Transfers.joins('2021-01-01', 'Standin'),
				Transfers.stopsPlaying('2021-06-01'),
				Transfers.changesRole('2021-09-01', 'Inactive', 'Standin'),
				Transfers.stopsPlaying('2022-01-01'),
				Transfers.leaves('2022-06-01')
			), SquadStatus.FORMER)

			assert.are_equal(2, #selection.stints)
			assert.are_equal('2021-06-01', dateOf(selection.stints[1].inactiveEntry))
			assert.are_equal('2022-01-01', dateOf(selection.stints[2].inactiveEntry))
		end)

		it('flags the inactive column even when the person has not left yet', function()
			local selection = selectionFor(historyOf(
				Transfers.joins('2021-01-01', 'Standin'),
				Transfers.stopsPlaying('2022-01-01')
			), SquadStatus.FORMER)

			assert.are_same({}, selection.stints)
			assert.is_true(selection.hasFormerInactiveEntry)
		end)

		it('gives someone who left and rejoined a row for each spell', function()
			local selection = selectionFor(historyOf(
				Transfers.joins('2020-01-01'),
				Transfers.leaves('2021-01-01'),
				Transfers.joins('2022-01-01'),
				Transfers.leaves('2023-01-01')
			), SquadStatus.FORMER)

			assert.are_equal(2, #selection.stints)
			assert.are_equal('2020-01-01', dateOf(selection.stints[1].joinEntry))
			assert.are_equal('2021-01-01', dateOf(selection.stints[1].leaveEntry))
			assert.are_equal('2022-01-01', dateOf(selection.stints[2].joinEntry))
			assert.are_equal('2023-01-01', dateOf(selection.stints[2].leaveEntry))
			-- rejoining is not a duplicate join, the first spell already ended
			assert.are_same({}, selection.warnings)
		end)

		it('does not carry an inactive spell into a later one', function()
			local selection = selectionFor(historyOf(
				Transfers.joins('2020-01-01', 'Standin'),
				Transfers.stopsPlaying('2020-06-01'),
				Transfers.leaves('2021-01-01'),
				Transfers.joins('2022-01-01'),
				Transfers.leaves('2023-01-01')
			), SquadStatus.FORMER)

			assert.are_equal('2020-06-01', dateOf(selection.stints[1].inactiveEntry))
			assert.is_nil(selection.stints[2].inactiveEntry)
		end)

		it('shows nothing for someone who has not left yet', function()
			local selection = selectionFor(
				historyOf(Transfers.joins('2021-01-01')), SquadStatus.FORMER)
			assert.are_same({}, selection.stints)
			assert.are_same({}, selection.warnings)
		end)

		it('ignores a second join with no leave between, and flags the page', function()
			local selection = selectionFor(historyOf(
				Transfers.joins('2021-01-01'),
				Transfers.joins('2021-06-01'),
				Transfers.leaves('2022-01-01')
			), SquadStatus.FORMER)

			assert.are_equal(1, #selection.stints)
			assert.are_equal('2021-01-01', dateOf(selection.stints[1].joinEntry))
			assert.are_equal(1, #selection.warnings)
			assert.are_equal('Invalid entry: Duplicate JOIN. Skipping', selection.warnings[1].reason)
		end)

		it('ignores a leave with no join before it, and flags the page', function()
			local selection = selectionFor(
				historyOf(Transfers.leaves('2022-01-01')), SquadStatus.FORMER)

			assert.are_same({}, selection.stints)
			assert.are_equal(1, #selection.warnings)
			assert.are_equal('Invalid entry: Missing previous JOIN. Skipping', selection.warnings[1].reason)
		end)

		it('still reads the rest of the history after a bad entry', function()
			local selection = selectionFor(historyOf(
				Transfers.leaves('2020-01-01'),
				Transfers.joins('2021-01-01'),
				Transfers.leaves('2022-01-01')
			), SquadStatus.FORMER)

			assert.are_equal(1, #selection.stints)
			assert.are_equal('2021-01-01', dateOf(selection.stints[1].joinEntry))
			assert.are_equal(1, #selection.warnings)
		end)

		it('reads a former inactive table the same way as a former one', function()
			local history = historyOf(Transfers.joins('2021-01-01'), Transfers.leaves('2022-01-01'))
			assert.are_same(
				SquadHistory.selectStints(history, SquadStatus.FORMER),
				SquadHistory.selectStints(history, SquadStatus.FORMER_INACTIVE)
			)
		end)
	end)

	describe('a history that yields no row', function()
		it('selects nothing for a status it does not recognise', function()
			assert.is_nil(SquadHistory.selectStints({entry{}}, nil))
		end)

		it('selects nothing for an empty history', function()
			assert.is_nil(SquadHistory.selectStints({}, SquadStatus.ACTIVE))
			assert.is_nil(SquadHistory.selectStints({}, SquadStatus.INACTIVE))
		end)

		it('selects nothing when an active squad has nobody active', function()
			assert.is_nil(SquadHistory.selectStints(historyOf(
				Transfers.joins('2021-01-01'),
				Transfers.leaves('2022-01-01')
			), SquadStatus.ACTIVE))
		end)

		it('still selects a former squad with no rows, so its warnings are reported', function()
			-- a leave with no join produces no row but must still flag the page
			local selection = selectionFor(historyOf(Transfers.leaves('2022-01-01')), SquadStatus.FORMER)

			assert.are_same({}, selection.stints)
			assert.are_equal(1, #selection.warnings)
		end)
	end)
end)
