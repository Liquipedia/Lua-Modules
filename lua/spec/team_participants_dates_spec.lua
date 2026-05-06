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

	describe('getPlayersDates', function()
		it('skips players with no pageName or TBD without querying', function()
			local result = TeamParticipantsRepository.getPlayersDates(
				{
					{pageName = nil, extradata = {}},
					{pageName = 'TBD', extradata = {}},
				},
				{'Team Liquid'}
			)
			assert.are_same({}, result)
			assert.stub(LpdbQuery).called(0)
		end)

		it('returns explicit dates without querying LPDB when both are set for all players', function()
			local result = TeamParticipantsRepository.getPlayersDates(
				{
					{pageName = 'Alexis', extradata = {joinDate = '2024-03-01', leaveDate = '2024-09-01'}},
				},
				{'Team Liquid'}
			)
			assert.are_equal('2024-03-01', result['Alexis'].joinDate)
			assert.are_equal('2024-09-01', result['Alexis'].leaveDate)
			assert.stub(LpdbQuery).called(0)
		end)

		it('fetches joinDate from active transfer for active player', function()
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function()
				return {{date = '2024-03-15', player = 'Alexis'}}
			end)

			local result = TeamParticipantsRepository.getPlayersDates(
				{{pageName = 'Alexis', extradata = {}}},
				{'Team Liquid'}
			)
			assert.are_equal('2024-03-15', result['Alexis'].joinDate)
			assert.is_nil(result['Alexis'].leaveDate)
		end)

		it('falls back to activeAlt when active query returns nothing', function()
			local callCount = 0
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function()
				callCount = callCount + 1
				if callCount == 2 then
					return {{date = '2024-04-01', player = 'Alexis'}}
				end
				return {}
			end)

			local result = TeamParticipantsRepository.getPlayersDates(
				{{pageName = 'Alexis', extradata = {}}},
				{'Team Liquid'}
			)
			assert.are_equal('2024-04-01', result['Alexis'].joinDate)
			assert.are_equal(2, callCount)
		end)

		it('fetches joinDate and leaveDate for former player', function()
			local callCount = 0
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function()
				callCount = callCount + 1
				if callCount == 1 then
					return {{date = '2024-02-01', player = 'Alexis'}} -- active → joinDate
				elseif callCount == 3 then
					return {{date = '2024-08-15', player = 'Alexis'}} -- former → leaveDate
				end
				return {}
			end)

			local result = TeamParticipantsRepository.getPlayersDates(
				{{pageName = 'Alexis', extradata = {status = 'former'}}},
				{'Team Liquid'}
			)
			assert.are_equal('2024-02-01', result['Alexis'].joinDate)
			assert.are_equal('2024-08-15', result['Alexis'].leaveDate)
		end)

		it('falls back to inactive query when former returns nothing for former player', function()
			local callCount = 0
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function()
				callCount = callCount + 1
				if callCount == 4 then
					return {{date = '2024-09-30', player = 'Alexis'}} -- inactive → leaveDate
				end
				return {}
			end)

			local result = TeamParticipantsRepository.getPlayersDates(
				{{pageName = 'Alexis', extradata = {status = 'former'}}},
				{'Team Liquid'}
			)
			assert.is_nil(result['Alexis'].joinDate)
			assert.are_equal('2024-09-30', result['Alexis'].leaveDate)
			assert.are_equal(4, callCount) -- active, activeAlt, former, inactive
		end)

		it('explicit joinDate takes precedence over LPDB result', function()
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function()
				return {{date = '2024-03-15', player = 'Alexis'}}
			end)

			local result = TeamParticipantsRepository.getPlayersDates(
				{{pageName = 'Alexis', extradata = {joinDate = '2023-01-01'}}},
				{'Team Liquid'}
			)
			assert.are_equal('2023-01-01', result['Alexis'].joinDate)
		end)

		it('queries against the team-template columns, not display-name columns', function()
			local capturedConditions
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function(_, options)
				capturedConditions = options.conditions
				return {}
			end)

			TeamParticipantsRepository.getPlayersDates(
				{{pageName = 'Alexis', extradata = {}}},
				{'team liquid'}
			)

			assert.is_truthy(capturedConditions:find('toteamtemplate', 1, true))
			assert.is_truthy(capturedConditions:find('fromteamtemplate', 1, true))
			assert.is_nil(capturedConditions:find('[[toteam::', 1, true))
			assert.is_nil(capturedConditions:find('[[fromteam::', 1, true))
		end)

		it('batches multiple players into a single query per status', function()
			local callCount = 0
			local capturedConditions = {}
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function(_, options)
				callCount = callCount + 1
				table.insert(capturedConditions, options.conditions)
				if callCount == 1 then
					return {{date = '2024-03-15', player = 'Alexis'}}
				elseif callCount == 2 then
					return {{date = '2024-04-20', player = 'Bob'}}
				end
				return {}
			end)

			local result = TeamParticipantsRepository.getPlayersDates(
				{
					{pageName = 'Alexis', extradata = {}},
					{pageName = 'Bob', extradata = {}},
				},
				{'Team Liquid'}
			)

			assert.are_equal('2024-03-15', result['Alexis'].joinDate)
			assert.are_equal('2024-04-20', result['Bob'].joinDate)
			-- 2 queries total (active + activeAlt) for 2 players, not 4 (one per player per status)
			assert.are_equal(2, callCount)
			assert.is_truthy(capturedConditions[1]:find('Alexis', 1, true))
			assert.is_truthy(capturedConditions[1]:find('Bob', 1, true))
			-- Second query (activeAlt) should only ask about Bob since Alexis already resolved
			assert.is_nil(capturedConditions[2]:find('"Alexis"', 1, true))
			assert.is_truthy(capturedConditions[2]:find('Bob', 1, true))
		end)

		it('picks the latest transfer per player when multiple rows are returned', function()
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function()
				return {
					{date = '2024-05-01', player = 'Alexis'},
					{date = '2024-03-01', player = 'Alexis'},
					{date = '2024-04-01', player = 'Bob'},
				}
			end)

			local result = TeamParticipantsRepository.getPlayersDates(
				{
					{pageName = 'Alexis', extradata = {}},
					{pageName = 'Bob', extradata = {}},
				},
				{'Team Liquid'}
			)
			assert.are_equal('2024-05-01', result['Alexis'].joinDate)
			assert.are_equal('2024-04-01', result['Bob'].joinDate)
		end)

		it('matches transfers under either underscore or space variant of the page name', function()
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function()
				return {{date = '2024-06-01', player = 'Some Player'}}
			end)

			local result = TeamParticipantsRepository.getPlayersDates(
				{{pageName = 'Some_Player', extradata = {}}},
				{'Team Liquid'}
			)
			assert.are_equal('2024-06-01', result['Some_Player'].joinDate)
		end)

		it('only queries former/inactive for players whose status is former', function()
			local capturedConditions = {}
			LpdbQuery:revert()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function(_, options)
				table.insert(capturedConditions, options.conditions)
				return {}
			end)

			TeamParticipantsRepository.getPlayersDates(
				{
					{pageName = 'Active', extradata = {}},
					{pageName = 'Former', extradata = {status = 'former'}},
				},
				{'Team Liquid'}
			)

			-- 4 calls total: active, activeAlt (both players), former, inactive (only former player)
			assert.are_equal(4, #capturedConditions)
			assert.is_truthy(capturedConditions[1]:find('Active', 1, true))
			assert.is_truthy(capturedConditions[1]:find('Former', 1, true))
			-- Latter two queries should only mention 'Former'
			assert.is_nil(capturedConditions[3]:find('"Active"', 1, true))
			assert.is_truthy(capturedConditions[3]:find('Former', 1, true))
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
