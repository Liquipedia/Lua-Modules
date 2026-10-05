--- Triple Comment to Enable our LLS Plugin
--[[
Tests for Module:Domain/TeamHistory/Model: reading transfer records into one team's history of a person.
]]

local TeamHistory = require('Module:Domain/TeamHistory/Model')
local Table = require('Module:Table')

local TransferType = TeamHistory.TransferType

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
	local result = TeamHistory.fromTransfer(record, TEAMS)
	assert(result, 'expected the transfer to be relevant to the team')
	return result
end

describe('Team history', function()

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
			assert.is_nil(TeamHistory.fromTransfer(transfer{
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
			assert.is_nil(TeamHistory.fromTransfer(transfer{
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
			local history = TeamHistory.fromTransfers({
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
			local history = TeamHistory.fromTransfers({
				transfer{player = 'Alice', fromteamtemplate = OTHER_TEAM, toteamtemplate = OTHER_TEAM},
			}, TEAMS)

			assert.are_same({}, history)
		end)

		it('returns an empty table when there are no transfers', function()
			assert.are_same({}, TeamHistory.fromTransfers({}, TEAMS))
		end)
	end)
end)
