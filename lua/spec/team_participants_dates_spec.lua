--- Triple Comment to Enable our LLS Plugin
describe('TeamParticipants player dates', function()
	local TeamParticipantsRepository
	local Variables
	local PageVariableNamespace
	local LpdbQuery

	before_each(function()
		Variables = require('Module:Variables')
		Variables.varDefine('tournament_startdate', '2024-01-01')
		Variables.varDefine('tournament_enddate', '2024-12-31')
		PageVariableNamespace = require('Module:PageVariableNamespace')
		TeamParticipantsRepository = require('Module:TeamParticipants/Repository')
		LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
	end)

	after_each(function()
		LpdbQuery:revert()
		Variables.varDefine('tournament_startdate')
		Variables.varDefine('tournament_enddate')
	end)

	describe('getPlayerDates', function()
		it('returns empty for player with no pageName', function()
			local dates = TeamParticipantsRepository.getPlayerDates(
				{pageName = nil, extradata = {}},
				{'Team Liquid'}
			)
			assert.are_same({}, dates)
			assert.stub(LpdbQuery).called(0)
		end)

		it('returns empty for TBD player', function()
			local dates = TeamParticipantsRepository.getPlayerDates(
				{pageName = 'TBD', extradata = {}},
				{'Team Liquid'}
			)
			assert.are_same({}, dates)
			assert.stub(LpdbQuery).called(0)
		end)

		it('returns explicit dates without querying LPDB when both are set', function()
			local dates = TeamParticipantsRepository.getPlayerDates(
				{pageName = 'Alexis', extradata = {joinDate = '2024-03-01', leaveDate = '2024-09-01'}},
				{'Team Liquid'}
			)
			assert.are_equal('2024-03-01', dates.joinDate)
			assert.are_equal('2024-09-01', dates.leaveDate)
			assert.stub(LpdbQuery).called(0)
		end)

		it('fetches joinDate from active transfer for active player', function()
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {{date = '2024-03-15'}} end)

			local dates = TeamParticipantsRepository.getPlayerDates(
				{pageName = 'Alexis', extradata = {}},
				{'Team Liquid'}
			)
			assert.are_equal('2024-03-15', dates.joinDate)
			assert.is_nil(dates.leaveDate)
		end)

		it('falls back to activeAlt when active query returns nothing', function()
			local callCount = 0
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function()
				callCount = callCount + 1
				if callCount == 2 then
					return {{date = '2024-04-01'}}
				end
				return {}
			end)

			local dates = TeamParticipantsRepository.getPlayerDates(
				{pageName = 'Alexis', extradata = {}},
				{'Team Liquid'}
			)
			assert.are_equal('2024-04-01', dates.joinDate)
			assert.are_equal(2, callCount)
		end)

		it('fetches joinDate and leaveDate for former player', function()
			local callCount = 0
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function()
				callCount = callCount + 1
				if callCount == 1 then
					return {{date = '2024-02-01'}} -- active → joinDate
				elseif callCount == 2 then
					return {{date = '2024-08-15'}} -- former → leaveDate
				end
				return {}
			end)

			local dates = TeamParticipantsRepository.getPlayerDates(
				{pageName = 'Alexis', extradata = {status = 'former'}},
				{'Team Liquid'}
			)
			assert.are_equal('2024-02-01', dates.joinDate)
			assert.are_equal('2024-08-15', dates.leaveDate)
		end)

		it('falls back to inactive query when former returns nothing for former player', function()
			local callCount = 0
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function()
				callCount = callCount + 1
				if callCount == 4 then
					return {{date = '2024-09-30'}} -- inactive → leaveDate
				end
				return {}
			end)

			local dates = TeamParticipantsRepository.getPlayerDates(
				{pageName = 'Alexis', extradata = {status = 'former'}},
				{'Team Liquid'}
			)
			assert.is_nil(dates.joinDate)
			assert.are_equal('2024-09-30', dates.leaveDate)
			assert.are_equal(4, callCount) -- active, activeAlt, former, inactive
		end)

		it('explicit joinDate takes precedence over LPDB result', function()
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {{date = '2024-03-15'}} end)

			local dates = TeamParticipantsRepository.getPlayerDates(
				{pageName = 'Alexis', extradata = {joinDate = '2023-01-01'}},
				{'Team Liquid'}
			)
			assert.are_equal('2023-01-01', dates.joinDate)
		end)

		it('queries against the team-template columns, not display-name columns', function()
			local capturedConditions
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function(_, options)
				capturedConditions = options.conditions
				return {}
			end)

			TeamParticipantsRepository.getPlayerDates(
				{pageName = 'Alexis', extradata = {}},
				{'team liquid'}
			)

			assert.is_truthy(capturedConditions:find('toteamtemplate', 1, true))
			assert.is_truthy(capturedConditions:find('fromteamtemplate', 1, true))
			assert.is_nil(capturedConditions:find('[[toteam::', 1, true))
			assert.is_nil(capturedConditions:find('[[fromteam::', 1, true))
		end)
	end)

	describe('setPageVars', function()
		it('writes joindate and leavedate to global vars under team prefixes', function()
			local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
			TeamTemplateMock.setUp()
			local globalVars = PageVariableNamespace()

			TeamParticipantsRepository.setPageVars({
				aliases = {'team liquid'},
				opponent = {
					players = {{
						pageName = 'Alexis',
						flag = 'us',
						displayName = 'alexis',
						faction = nil,
						apiId = nil,
						extradata = {
							type = 'player',
							joinDate = '2024-03-15',
							leaveDate = nil,
						},
					}},
				},
			})

			assert.are_equal('2024-03-15', globalVars:get('Team Liquid_p1joindate'))
			assert.is_nil(globalVars:get('Team Liquid_p1leavedate'))
			TeamTemplateMock.tearDown()
		end)

		it('writes both joindate and leavedate for former player', function()
			local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
			TeamTemplateMock.setUp()
			local globalVars = PageVariableNamespace()

			TeamParticipantsRepository.setPageVars({
				aliases = {'team liquid'},
				opponent = {
					players = {{
						pageName = 'Alexis',
						flag = 'us',
						displayName = 'alexis',
						faction = nil,
						apiId = nil,
						extradata = {
							type = 'player',
							status = 'former',
							joinDate = '2024-02-01',
							leaveDate = '2024-08-15',
						},
					}},
				},
			})

			assert.are_equal('2024-02-01', globalVars:get('Team Liquid_p1joindate'))
			assert.are_equal('2024-08-15', globalVars:get('Team Liquid_p1leavedate'))
			TeamTemplateMock.tearDown()
		end)
	end)

	describe('parsePlayer date input', function()
		it('stores explicit joindate from wiki input in extradata', function()
			local TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')
			local player = TeamParticipantsWikiParser.parsePlayer{'Alexis', joindate = '2024-03-01'}
			assert.are_equal('2024-03-01', player.extradata.joinDate)
			assert.is_nil(player.extradata.leaveDate)
		end)

		it('stores explicit leavedate from wiki input in extradata', function()
			local TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')
			local player = TeamParticipantsWikiParser.parsePlayer{'Alexis', leavedate = '2024-09-01'}
			assert.is_nil(player.extradata.joinDate)
			assert.are_equal('2024-09-01', player.extradata.leaveDate)
		end)

		it('stores nothing for missing date input', function()
			local TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')
			local player = TeamParticipantsWikiParser.parsePlayer{'Alexis'}
			assert.is_nil(player.extradata.joinDate)
			assert.is_nil(player.extradata.leaveDate)
		end)

		it('treats empty string date input as nil', function()
			local TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')
			local player = TeamParticipantsWikiParser.parsePlayer{'Alexis', joindate = ''}
			assert.is_nil(player.extradata.joinDate)
		end)
	end)
end)
