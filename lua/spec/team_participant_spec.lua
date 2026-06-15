--- Triple Comment to Enable our LLS Plugin
describe('Team Participant', function()
	insulate('integration tests', function()
		it('renders team participants template with multiple teams', function()
			local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
			TeamTemplateMock.setUp()
			local LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
			local LpdbPlacementStore = stub(mw.ext.LiquipediaDB, 'lpdb_placement', function() end)

			local TeamParticipantsController = require('Module:TeamParticipants/Controller')

			GoldenTest('team_participant',
				tostring(TeamParticipantsController.fromTemplate{
					{
						'Team Liquid',
						players = {
							{'alexis', number = 7},
							{'dodonut'},
							{'meL'},
							{'Noia'},
							{'sarah'},
							{'effys', role = 'Head Coach', type = 'staff'},
							{'Veer', role = 'Coach', type = 'staff', played = false}
						},
						qualification = {
							method = 'qual',
							url = 'https://google.com',
							text = 'FooBar',
						},
						notes = {
							{'SOME TEXT HERE'},
						}
					},
					{
						'bds',
						qualification = {
							method = 'invite',
							text = 'Invited',
						},
						players = {
							{'ElectricalBoy'},
							{'hjpalpha'},
							{'Eetu'},
							{'SyntacticSugar'},
							{'SyntacticSalt'},
							{'Rathoz', role = 'Coach', type = 'staff'},
						},
						notes = {
							{'Best Team in the World!', highlighted = true},
						}
					},
					{
						'mouz',
						qualification = {
							method = 'invite',
							page = 'Testpage',
							text = 'Invited',
						},
						players = {},
					},
				}),
				[[<style>.collapsed > .should-collapse { display: block !important; }</style>]]
			)

			LpdbQuery:revert()
			LpdbPlacementStore:revert()
			TeamTemplateMock.tearDown()
		end)
	end)

	describe('TeamParticipants player parsing', function()
		local TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')

		describe('parsePlayer status', function()
			it('passes status through from input', function()
				local player = TeamParticipantsWikiParser.parsePlayer({'s1mple', status = 'former'})
				assert.are_equal('former', player.extradata.status)
			end)

			it('passes status through independent of type', function()
				local player = TeamParticipantsWikiParser.parsePlayer({'s1mple', type = 'sub', status = 'inactive'})
				assert.are_equal('inactive', player.extradata.status)
			end)

			it('status is nil when not provided', function()
				local player = TeamParticipantsWikiParser.parsePlayer({'s1mple'})
				assert.is_nil(player.extradata.status)
			end)
		end)

		describe('Player Number', function()
			it('parses number string as integer', function()
				local player = TeamParticipantsWikiParser.parsePlayer{'PlayerName', number = '5'}
				assert.are_equal(5, player.extradata.number)
			end)

			it('parses number passed as a Lua number', function()
				local player = TeamParticipantsWikiParser.parsePlayer{'PlayerName', number = 7}
				assert.are_equal(7, player.extradata.number)
			end)

			it('returns nil when number is absent', function()
				local player = TeamParticipantsWikiParser.parsePlayer{'PlayerName'}
				assert.is_nil(player.extradata.number)
			end)

			it('returns nil for non-numeric number input', function()
				local player = TeamParticipantsWikiParser.parsePlayer{'PlayerName', number = 'abc'}
				assert.is_nil(player.extradata.number)
			end)
		end)

		describe('Qualification Placement', function()
			local date = os.date("!*t", os.time()) --[[@as osdateparam]]
			insulate('placement field parsing', function()
				local TeamTemplateMock
				local LpdbQuery

				before_each(function()
					TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
					TeamTemplateMock.setUp()
					LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
				end)

				after_each(function()
					LpdbQuery:revert()
					TeamTemplateMock.tearDown()
				end)

				it('parses valid positive integer placement as string', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier A',
							placement = '5'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.are_equal('5', result.qualification.placement)
				end)

				it('parses valid positive range of placements', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier B',
							placement = '3-4'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.are_equal('3-4', result.qualification.placement)
				end)

				it('parses valid positive integer placement as number', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier B',
							placement = 3
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.are_equal('3', result.qualification.placement)
				end)

				it('rejects decimal placement', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier G',
							placement = '2.9'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
				end)

				it('handles large positive placement numbers', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier H',
							placement = '999'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.are_equal('999', result.qualification.placement)
				end)

				it('ignores zero placement', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier C',
							placement = '0'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
				end)

				it('ignores negative placement', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier D',
							placement = '-1'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
				end)

				it('ignores invalid non-numeric placement', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier E',
							placement = 'abc'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
				end)

				it('handles missing placement gracefully', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier F'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
				end)

				it('preserves other qualification fields when placement is present', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Custom Text',
							placement = '7'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.are_equal('7', result.qualification.placement)
					assert.are_equal('qual', result.qualification.method)
					assert.are_equal('Custom Text', result.qualification.text)
				end)
			end)

			insulate('placement validation warnings', function()
				local TeamTemplateMock
				local LpdbQuery

				before_each(function()
					TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
					TeamTemplateMock.setUp()
					LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
				end)

				after_each(function()
					LpdbQuery:revert()
					TeamTemplateMock.tearDown()
				end)

				it('generates warning for zero placement', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier C',
							placement = '0'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
					assert.are_equal(1, #result.warnings)
					assert.matches('Invalid placement: 0', result.warnings[1])
				end)

				it('generates warning for negative placement', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier D',
							placement = '-5'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
					assert.are_equal(1, #result.warnings)
					assert.matches('Invalid placement: %-5$', result.warnings[1])
				end)

				it('generates warning for non-numeric placement', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier E',
							placement = 'abc'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
					assert.are_equal(1, #result.warnings)
					assert.matches('Invalid placement: abc$', result.warnings[1])
				end)

				it('generates warning for placement with special characters', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier X',
							placement = '#1'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
					assert.are_equal(1, #result.warnings)
					assert.matches('Invalid placement: #1$', result.warnings[1])
				end)

				it('generates warning for ordinal placement', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier Y',
							placement = '1st'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
					assert.are_equal(1, #result.warnings)
					assert.matches('Invalid placement: 1st$', result.warnings[1])
				end)

				it('generates warning for decimal placement', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier G',
							placement = '2.9'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
					assert.are_equal(1, #result.warnings)
					assert.matches('Invalid placement: 2%.9$', result.warnings[1])
				end)

				it('does not generate warning for valid positive placement', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier Valid',
							placement = '5'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.are_equal('5', result.qualification.placement)
					assert.are_equal(0, #result.warnings)
				end)

				it('does not generate warning when no placement is provided', function()
					local input = {
						'team liquid',
						qualification = {
							method = 'qual',
							text = 'Qualifier No Placement'
						}
					}
					local result = TeamParticipantsWikiParser.parseParticipant(input, date)
					assert.is_nil(result.qualification.placement)
					assert.are_equal(0, #result.warnings)
				end)
			end)
		end)

		describe('TBD Functionality', function()
			local TeamParticipantsController = require('Module:TeamParticipants/Controller')
			local Array = require('Module:Array')

			describe('createTBDPlayers', function()
				it('check', function()
					local players = TeamParticipantsWikiParser.createTBDPlayers(3)
					assert.are_equal(3, #players)
					assert.are_equal('TBD', players[1].displayName)
					assert.are_equal('player', players[1].extradata.type)
					assert.is_not_nil(players[1].extradata)

					assert.are_equal(0, #TeamParticipantsWikiParser.createTBDPlayers(0))
				end)
			end)

			describe('fillIncompleteRoster', function()
				it('fills roster when player count is below expected', function()
					local opponent = {
						players = {
							{displayName = 'Player1', extradata = {type = 'player'}},
							{displayName = 'Player2', extradata = {type = 'player'}},
							{displayName = 'Player3', extradata = {type = 'player'}},
						}
					}

					TeamParticipantsWikiParser.fillIncompleteRoster(opponent, 5)

					assert.are_equal(5, #opponent.players)
					assert.are_equal('Player1', opponent.players[1].displayName)
					assert.are_equal('TBD', opponent.players[4].displayName)
					assert.are_equal('TBD', opponent.players[5].displayName)
				end)

				it('does not fill when roster is complete', function()
					local opponent = {
						players = {
							{displayName = 'Player1', extradata = {type = 'player'}},
							{displayName = 'Player2', extradata = {type = 'player'}},
							{displayName = 'Player3', extradata = {type = 'player'}},
							{displayName = 'Player4', extradata = {type = 'player'}},
							{displayName = 'Player5', extradata = {type = 'player'}},
						}
					}

					TeamParticipantsWikiParser.fillIncompleteRoster(opponent, 5)

					assert.are_equal(5, #opponent.players)
					assert.are_equal('Player5', opponent.players[5].displayName)
				end)

				it('does not fill when roster exceeds expected', function()
					local opponent = {
						players = {
							{displayName = 'Player1', extradata = {type = 'player'}},
							{displayName = 'Player2', extradata = {type = 'player'}},
							{displayName = 'Player3', extradata = {type = 'player'}},
							{displayName = 'Player4', extradata = {type = 'player'}},
							{displayName = 'Player5', extradata = {type = 'player'}},
							{displayName = 'Player6', extradata = {type = 'player'}},
							{displayName = 'Player7', extradata = {type = 'player'}},
						}
					}

					TeamParticipantsWikiParser.fillIncompleteRoster(opponent, 5)

					assert.are_equal(7, #opponent.players)
				end)

				it('only counts type=player when checking roster size', function()
					local opponent = {
						players = {
							{displayName = 'Player1', extradata = {type = 'player'}},
							{displayName = 'Player2', extradata = {type = 'player'}},
							{displayName = 'Player3', extradata = {type = 'player'}},
							{displayName = 'Coach1', extradata = {type = 'staff'}},
							{displayName = 'Coach2', extradata = {type = 'staff'}},
						}
					}

					TeamParticipantsWikiParser.fillIncompleteRoster(opponent, 5)

					assert.are_equal(7, #opponent.players)
					local activePlayers = Array.filter(opponent.players, function(p)
						return p.extradata.type == 'player' and not p.extradata.status
					end)
					assert.are_equal(5, #activePlayers)
				end)

				it('does not count players with a status as active', function()
					local opponent = {
						players = {
							TeamParticipantsWikiParser.parsePlayer({'Player1'}),
							TeamParticipantsWikiParser.parsePlayer({'Player2'}),
							TeamParticipantsWikiParser.parsePlayer({'Former1', status = 'former'}),
							TeamParticipantsWikiParser.parsePlayer({'Sub1', status = 'sub'}),
						}
					}

					TeamParticipantsWikiParser.fillIncompleteRoster(opponent, 5)

					local activePlayers = Array.filter(opponent.players, function(p)
						return p.extradata.type == 'player' and not p.extradata.status
					end)
					assert.are_equal(5, #activePlayers)
				end)

				it('handles missing data gracefully', function()
					local opponent1 = {
						players = {
							{displayName = 'Player1', extradata = {type = 'player'}},
						}
					}
					TeamParticipantsWikiParser.fillIncompleteRoster(opponent1, nil)
					assert.are_equal(1, #opponent1.players)

					local opponent2 = {}
					TeamParticipantsWikiParser.fillIncompleteRoster(opponent2, 5)
					assert.is_nil(opponent2.players)
				end)
			end)

			insulate('parseWikiInput with expectedPlayerCount', function()
				it('returns expectedPlayerCount from minimumplayers arg', function()
					local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
					TeamTemplateMock.setUp()
					local LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)

					local args = {
						{
							'team liquid',
							players = {
								{'player1'},
							}
						},
						minimumplayers = '5',
						date = '2024-01-01',
					}

					local result = TeamParticipantsWikiParser.parseWikiInput(args)

					assert.are_equal(5, result.expectedPlayerCount)

					LpdbQuery:revert()
					TeamTemplateMock.tearDown()
				end)

				it('returns nil when minimumplayers not provided', function()
					local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
					TeamTemplateMock.setUp()
					local LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)

					local args = {
						{
							'team liquid',
							players = {
								{'player1'},
							}
						},
						date = '2024-01-01',
					}

					local result = TeamParticipantsWikiParser.parseWikiInput(args)

					assert.is_nil(result.expectedPlayerCount)

					LpdbQuery:revert()
					TeamTemplateMock.tearDown()
				end)
			end)

			insulate('TBD Auto-fill integration', function()
				it('auto-fills incomplete roster after parsing', function()
					local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
					TeamTemplateMock.setUp()
					local LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)

					SetActiveWiki('valorant')

					local parsedData = TeamParticipantsWikiParser.parseWikiInput{
						{
							'Team Liquid',
							players = {
								{'alexis'},
								{'dodonut'},
								{'meL'},
							}
						},
						minimumplayers = '5',
						date = '2024-01-01',
					}

				TeamParticipantsController.importParticipants(parsedData)
				TeamParticipantsController.fillIncompleteRosters(parsedData)

				local opponent = parsedData.participants[1].opponent
				local activePlayers = Array.filter(opponent.players, function(p)
					return p.extradata.type == 'player' and not p.extradata.status
				end)

				assert.are_equal(5, #activePlayers)
					assert.are_equal('alexis', activePlayers[1].displayName)
					assert.are_equal('TBD', activePlayers[4].displayName)
					assert.are_equal('TBD', activePlayers[5].displayName)

					LpdbQuery:revert()
					TeamTemplateMock.tearDown()
				end)

				it('does not auto-fill opponents with potential qualifiers', function()
					local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
					TeamTemplateMock.setUp()
					local LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
					local Opponent = require('Module:Opponent')

					SetActiveWiki('valorant')

					local parsedData = {
						participants = {
							{
								opponent = Opponent.tbd(Opponent.team),
								potentialQualifiers = {},
							}
						},
						expectedPlayerCount = 5,
					}

					parsedData.participants[1].opponent.players = {}

					TeamParticipantsController.importParticipants(parsedData)

					assert.are_equal(0, #parsedData.participants[1].opponent.players)

					LpdbQuery:revert()
					TeamTemplateMock.tearDown()
				end)
			end)
		end)

		describe('missing team template', function()
			local date = os.date("!*t", os.time()) --[[@as osdateparam]]
			insulate('parseParticipant', function()
				local TeamTemplateMock
				before_each(function()
					TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
					TeamTemplateMock.setUp()
				end)
				after_each(function()
					TeamTemplateMock.tearDown()
				end)

				it('marks the participant broken without calling Opponent.resolve', function()
					local result = TeamParticipantsWikiParser.parseParticipant({'definitely missing'}, date)
					assert.is_true(result.broken)
					assert.is_truthy(result.errorMessage)
				end)

				it('leaves valid templates untouched', function()
					local result = TeamParticipantsWikiParser.parseParticipant({'team liquid'}, date)
					assert.is_nil(result.broken)
				end)
			end)
		end)

	end)

	describe('player dates', function()
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
								results = true,
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
								results = true,
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


end)

describe('Team Participants Repository', function()
	local TeamParticipantsRepository
	local Table
	local Variables
	local Json
	local PageVariableNamespace

	before_each(function()
		TeamParticipantsRepository = require('Module:TeamParticipants/Repository')
		Table = require('Module:Table')
		Variables = require('Module:Variables')
		Json = require('Module:Json')
		PageVariableNamespace = require('Module:PageVariableNamespace')
	end)

	local function createBasicParticipant(overrides)
		return Table.merge({
			opponent = {
				type = 'team',
				template = 'team liquid',
				name = 'Team Liquid',
				players = {
					{displayName = 'Player1', pageName = 'Player1', flag = 'us', extradata = {type = 'player', results = true}},
					{displayName = 'Player2', pageName = 'Player2', flag = 'ca', extradata = {type = 'player', results = true}},
				}
			},
			aliases = {'Team Liquid', 'TL'},
			qualification = nil,
			potentialQualifiers = nil,
		}, overrides or {})
	end

	local function createPrizepoolRecord(overrides)
		return Table.merge({
			objectName = 'ranking_team liquid',
			tournament = 'Test Tournament',
			parent = 'Test Series',
			series = 'Test',
			mode = '5v5',
			type = 'Online',
			placement = '1',
			prizemoney = 10000,
			opponentname = 'Team Liquid',
			opponenttype = 'team',
			opponenttemplate = 'team liquid',
			extradata = {},
		}, overrides or {})
	end

	describe('save', function()
		insulate('saves participant to LPDB placement table', function()
			local TeamTemplateMock
			local LpdbQuery
			local LpdbPlacementStore

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()

				Variables.varDefine('tournament_name', 'Test Tournament')
				Variables.varDefine('tournament_parent', 'Test Parent')
				Variables.varDefine('tournament_series', 'Test Series')
				Variables.varDefine('tournament_mode', '5v5')
				Variables.varDefine('tournament_type', 'Online')

				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
				LpdbPlacementStore = stub(mw.ext.LiquipediaDB, 'lpdb_placement', function() end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
				LpdbPlacementStore:revert()

				Variables.varDefine('tournament_name', nil)
				Variables.varDefine('tournament_parent', nil)
				Variables.varDefine('tournament_series', nil)
				Variables.varDefine('tournament_mode', nil)
				Variables.varDefine('tournament_type', nil)
			end)

			it('generates objectName as ranking_teamname for regular teams', function()
				local participant = createBasicParticipant({
					opponent = {
						type = 'team',
						template = 'team liquid',
						name = 'Team Liquid',
						players = {}
					}
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				assert.are_equal('ranking_team liquid', callArgs[1])
			end)

			it('generates unique objectName for TBD teams with counter', function()
				local tbdOpponent = {type = 'team', template = 'tbd', name = 'TBD', players = {}}
				TeamParticipantsRepository.save(createBasicParticipant({opponent = tbdOpponent}))
				TeamParticipantsRepository.save(createBasicParticipant({opponent = tbdOpponent}))
				assert.are_equal('participant_tbd_1', LpdbPlacementStore.calls[1].vals[1])
				assert.are_equal('participant_tbd_2', LpdbPlacementStore.calls[2].vals[1])
			end)

			it('uses tournament defaults when no prizepool record exists', function()
				local participant = createBasicParticipant()

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.are_equal('Test Tournament', data.tournament)
				assert.are_equal('Test Parent', data.parent)
				assert.are_equal('Test Series', data.series)
				assert.are_equal('5v5', data.mode)
				assert.are_equal('Online', data.type)
				assert.is_nil(data.individualprizemoney)
			end)

			it('sets qualifierpage for tournament type qualification', function()
				local participant = createBasicParticipant({
					qualification = {
						type = 'tournament',
						method = 'qual',
						text = 'Regional Qualifier',
						tournament = {
							pageName = 'Test/Regional_Qualifier',
							displayName = 'Regional Qualifier',
						}
					}
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.are_equal('Test/Regional_Qualifier', data.qualifierpage)
				assert.are_equal('Regional Qualifier', data.qualifier)
			end)

			it('sets qualifierurl for external type qualification', function()
				local participant = createBasicParticipant({
					qualification = {
						type = 'external',
						method = 'qual',
						text = 'External Qualifier',
						url = 'https://example.com/qualifier',
					}
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.are_equal('https://example.com/qualifier', data.qualifierurl)
				assert.are_equal('External Qualifier', data.qualifier)
			end)

			it('stores opponentaliases in extradata', function()
				local participant = createBasicParticipant({
					aliases = {'Team Liquid', 'TL', 'Liquid'},
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])
				local extradata = Json.parseIfString(data.extradata)

				assert.are_same({'Team Liquid', 'TL', 'Liquid'}, extradata.opponentaliases)
			end)

			it('serializes potentialQualifiers in extradata', function()
				local participant = createBasicParticipant({
					opponent = {
						type = 'team',
						template = 'tbd',
						name = 'TBD',
						players = {}
					},
					potentialQualifiers = {
						{type = 'team', template = 'team liquid', name = 'Team Liquid'},
						{type = 'team', template = 'bds', name = 'BDS'},
					}
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])
				local extradata = Json.parseIfString(data.extradata)

				assert.are_same({'Team Liquid', 'Team BDS'}, extradata.potentialQualifiers)
			end)

			it('excludes staff when splitting prizemoney (subs still count)', function()
				local getRecordsStub = stub(TeamParticipantsRepository, 'getPrizepoolRecordsForTeam')
				getRecordsStub.returns({createPrizepoolRecord({prizemoney = 6000, opponenttemplate = 'bds'})})

				local participant = createBasicParticipant({
					opponent = {
						type = 'team',
						template = 'bds',
						name = 'BDS',
						players = {
							{displayName = 'P1', pageName = 'P1', extradata = {type = 'player', results = true}},
							{displayName = 'P2', pageName = 'P2', extradata = {type = 'player', results = true}},
							{displayName = 'Sub1', pageName = 'Sub1', extradata = {type = 'player', status = 'sub', results = true}},
							{displayName = 'Coach', pageName = 'Coach', extradata = {type = 'staff', results = true}},
						}
					}
				})

				TeamParticipantsRepository.save(participant)

				local data = Json.parseIfString(LpdbPlacementStore.calls[1].vals[2])
				-- 6000 split across 3 non-staff (P1, P2, Sub1); staff excluded
				assert.are_equal(2000, data.individualprizemoney)

				getRecordsStub:revert()
			end)

			it('merges with existing prizepool data', function()
				local participant = createBasicParticipant()

				local getRecordsStub = stub(TeamParticipantsRepository, 'getPrizepoolRecordsForTeam')
				getRecordsStub.returns({createPrizepoolRecord({
					placement = '3',
					prizemoney = 5000,
					tournament = 'Prizepool Tournament',
				})})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.are_equal('3', data.placement)
				assert.are_equal(5000, data.prizemoney)
				assert.are_equal('Prizepool Tournament', data.tournament)

				getRecordsStub:revert()
			end)
		end)
	end)

	describe('setPageVars', function()
		insulate('sets page variables for team aliases', function()
			local TeamTemplateMock
			local globalVars

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				globalVars = PageVariableNamespace()
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
			end)

			it('sets page variables with correct prefixes and suffixes', function()
				local participant = createBasicParticipant({
					aliases = {'Team Liquid'},
					opponent = {
						type = 'team',
						template = 'team liquid',
						name = 'Team Liquid',
						players = {
							{displayName = 'DisplayName', pageName = 'ActualPageName', flag = 'us',
								extradata = {type = 'player', results = true}},
							{displayName = 'Player2', pageName = 'Player2', flag = 'ca',
								extradata = {type = 'player', results = true}},
							{displayName = 'Coach1', pageName = 'Coach1', flag = 'gb',
								extradata = {type = 'staff', results = true}},
						}
					}
				})

				TeamParticipantsRepository.setPageVars(participant)

				assert.are_equal('ActualPageName', globalVars:get('Team Liquid_p1'))
				assert.are_equal('DisplayName', globalVars:get('Team Liquid_p1dn'))
				assert.are_equal('us', globalVars:get('Team Liquid_p1flag'))
				assert.are_equal('Player2', globalVars:get('Team Liquid_p2'))
				assert.are_equal('Coach1', globalVars:get('Team Liquid_c1'))
				assert.are_equal('ActualPageName', globalVars:get('Team_Liquid_p1'))
			end)
		end)
	end)

	describe('getPrizepoolRecordsForTeam', function()
		insulate('filters prizepool records by opponent matching', function()
			local TeamTemplateMock
			local getPrizepoolRecordsStub

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				getPrizepoolRecordsStub = stub(TeamParticipantsRepository, 'getPrizepoolRecords')
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				getPrizepoolRecordsStub:revert()
			end)

			it('returns matching records when opponent matches', function()
				local opponent = {
					type = 'team',
					template = 'team liquid',
					name = 'Team Liquid',
				}

				getPrizepoolRecordsStub.returns({
					createPrizepoolRecord({
						opponentname = 'Team Liquid',
						opponenttype = 'team',
						opponenttemplate = 'team liquid',
					})
				})

				local result = TeamParticipantsRepository.getPrizepoolRecordsForTeam(opponent)

				assert.are_equal(1, #result)
				assert.are_equal('Team Liquid', result[1].opponentname)
			end)
		end)
	end)

	describe('getPrizepoolRecords', function()
		-- getPrizepoolRecords is memoized at module load, so force a fresh module instance per case
		-- (the module is already cached here via the Controller integration tests above).
		local function freshGetPrizepoolRecords()
			for name in pairs(package.loaded) do
				if name:find('TeamParticipants') and name:find('Repository') then
					package.loaded[name] = nil
				end
			end
			return require('Module:TeamParticipants/Repository').getPrizepoolRecords()
		end

		insulate('flattens multiple prizepool indices', function()
			local prizePoolVars = PageVariableNamespace('PrizePool')
			prizePoolVars:delete('placementRecords.1')
			prizePoolVars:delete('placementRecords.2')
			prizePoolVars:set('placementRecords.1', Json.stringify({
				createPrizepoolRecord({placement = '1'}),
			}))
			prizePoolVars:set('placementRecords.2', Json.stringify({
				createPrizepoolRecord({placement = '2'}),
			}))
			local result = freshGetPrizepoolRecords()
			assert.are_equal(2, #result)
			assert.are_equal('1', result[1].placement)
			assert.are_equal('2', result[2].placement)
		end)
	end)
end)

describe('Team Participants Controller', function()
	local TeamParticipantsController
	local Array
	local Table

	before_each(function()
		TeamParticipantsController = require('Module:TeamParticipants/Controller')
		Array = require('Module:Array')
		Table = require('Module:Table')
	end)

	local function createSquadMember(overrides)
		return Table.merge({
			id = 'DefaultPlayer',
			link = 'DefaultPlayer',
			name = 'Default Player',
			nationality = 'us',
			role = 'Player',
			type = 'player',
			joindate = '2024-01-01',
			leavedate = '2099-12-31',
		}, overrides or {})
	end

	describe('importSquadMembersFromDatabase', function()
		insulate('fetches squad members from database', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function(entity)
					if entity == 'squadplayer' then
						return {
							createSquadMember({
								id = 'Player1',
								link = 'Player1',
								name = 'Player One',
							}),
							createSquadMember({
								id = 'Player2',
								link = 'Player2',
								name = 'Player Two',
							}),
							createSquadMember({
								id = 'Coach1',
								link = 'Coach1',
								name = 'Coach One',
								role = 'Coach',
								type = 'staff',
							}),
						}
					end
					return {}
				end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('returns squad members with correct types for valid team', function()
				local participant = {
					opponent = {template = 'team liquid'},
					date = os.time(),
				}

				local result = TeamParticipantsController.importSquadMembersFromDatabase(participant)

				assert.are_equal(3, #result)

				local playerCount = #Array.filter(result, function(member)
					return member.extradata.type == 'player'
				end)
				assert.are_equal(2, playerCount)

				local staffCount = #Array.filter(result, function(member)
					return member.extradata.type == 'staff'
				end)
				assert.are_equal(1, staffCount)
			end)
		end)

		insulate('handles substitutes', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function(entity)
					if entity == 'squadplayer' then
						return {
							createSquadMember({
								id = 'SubPlayer',
								link = 'SubPlayer',
								name = 'Sub Player',
								role = 'Substitute',
							}),
						}
					end
					return {}
				end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('marks substitute role with status=sub', function()
				local participant = {
					opponent = {template = 'team liquid'},
					date = os.time(),
				}

				local result = TeamParticipantsController.importSquadMembersFromDatabase(participant)

				-- "sub" is tracked via extradata.status; extradata.type stays 'player'
				local subs = Array.filter(result, function(member)
					return member.extradata.status == 'sub'
				end)
				assert.are_equal(1, #subs)
				assert.are_equal('SubPlayer', subs[1].displayName)
				assert.are_equal('player', subs[1].extradata.type)
			end)
		end)

		insulate('filters squad based on date range', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function(entity)
					if entity == 'squadplayer' then
						return {
							createSquadMember({
								id = 'CurrentPlayer',
								link = 'CurrentPlayer',
								name = 'Current Player',
								joindate = '2020-01-01',
								leavedate = '2099-12-31',
							}),
							createSquadMember({
								id = 'FormerPlayer',
								link = 'FormerPlayer',
								name = 'Former Player',
								joindate = '2020-01-01',
								leavedate = '2021-12-31',
							}),
						}
					end
					return {}
				end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('only returns members active during tournament', function()
				local participant = {
					opponent = {template = 'team liquid'},
					date = os.time(),
				}

				local result = TeamParticipantsController.importSquadMembersFromDatabase(participant)

				assert.are_equal(1, #result)
				assert.are_equal('CurrentPlayer', result[1].displayName)
			end)
		end)
	end)

	describe('mergeManualAndImportedPlayers', function()
		it('prepends new imported players to manual list', function()
			local manualPlayers = {
				{displayName = 'ManualPlayer1', pageName = 'ManualPlayer1', extradata = {type = 'player'}},
			}
			local importedPlayers = {
				{displayName = 'ImportedPlayer1', pageName = 'ImportedPlayer1', extradata = {type = 'player'}},
				{displayName = 'ImportedPlayer2', pageName = 'ImportedPlayer2', extradata = {type = 'player'}},
			}

			TeamParticipantsController.mergeManualAndImportedPlayers(manualPlayers, importedPlayers)

			-- Imported players are inserted at the front, manual players keep their order at the back
			assert.are_equal(3, #manualPlayers)
			assert.are_equal('ImportedPlayer2', manualPlayers[1].pageName)
			assert.are_equal('ImportedPlayer1', manualPlayers[2].pageName)
			assert.are_equal('ManualPlayer1', manualPlayers[3].pageName)
		end)

		it('deep merges when player exists in both lists', function()
			local manualPlayers = {
				{
					displayName = 'Player1',
					pageName = 'Player1',
					extradata = {
						type = 'player',
						manualData = 'manual',
					}
				},
			}
			local importedPlayers = {
				{
					displayName = 'Player1Imported',
					pageName = 'Player1',
					flag = 'us',
					extradata = {
						type = 'player',
						importedData = 'imported',
					}
				},
			}

			TeamParticipantsController.mergeManualAndImportedPlayers(manualPlayers, importedPlayers)

			assert.are_equal(1, #manualPlayers)
			assert.are_equal('manual', manualPlayers[1].extradata.manualData)
			assert.are_equal('imported', manualPlayers[1].extradata.importedData)
		end)

		it('manual data takes precedence over imported', function()
			local manualPlayers = {
				{
					displayName = 'ManualName',
					pageName = 'Player1',
					flag = 'us',
					extradata = {type = 'player'}
				},
			}
			local importedPlayers = {
				{
					displayName = 'ImportedName',
					pageName = 'Player1',
					flag = 'ca',
					extradata = {type = 'sub'}
				},
			}

			TeamParticipantsController.mergeManualAndImportedPlayers(manualPlayers, importedPlayers)

			assert.are_equal(1, #manualPlayers)
			assert.are_equal('ManualName', manualPlayers[1].displayName)
			assert.are_equal('us', manualPlayers[1].flag)
			assert.are_equal('player', manualPlayers[1].extradata.type)
		end)
	end)

	describe('importParticipants', function()
		it('skips import when shouldImportFromDb is false', function()
			local parsedData = {
				participants = {
					{
						opponent = {
							template = 'team liquid',
							players = {
								{displayName = 'Player1', pageName = 'Player1'},
							}
						},
						shouldImportFromDb = false,
					}
				}
			}

			TeamParticipantsController.importParticipants(parsedData)

			assert.are_equal(1, #parsedData.participants[1].opponent.players)
		end)
	end)

	insulate('fromTemplate Integration', function()
		local TeamTemplateMock
		local LpdbQuery
		local LpdbPlacementStore
		local Variables

		before_each(function()
			TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
			TeamTemplateMock.setUp()
			Variables = require('Module:Variables')
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
			LpdbPlacementStore = stub(mw.ext.LiquipediaDB, 'lpdb_placement', function() end)
		end)

		after_each(function()
			TeamTemplateMock.tearDown()
			LpdbPlacementStore:revert()
			LpdbQuery:revert()
		end)

		it('store=false parameter skips LPDB storage', function()
			local args = {
				{
					'team liquid',
					players = {
						{'player1'},
					}
				},
				store = false,
			}

			TeamParticipantsController.fromTemplate(args)

			assert.stub(LpdbPlacementStore).was_not.called()
		end)

		it('store=true enables LPDB storage', function()
			local args = {
				{
					'team liquid',
					players = {
						{'player1'},
					}
				},
				store = true,
			}

			TeamParticipantsController.fromTemplate(args)

			assert.stub(LpdbPlacementStore).was.called()
		end)

		it('disable_LPDB_storage variable prevents storage', function()
			Variables.varDefine('disable_LPDB_storage', '1')

			local args = {
				{
					'team liquid',
					players = {
						{'player1'},
					}
				},
			}

			TeamParticipantsController.fromTemplate(args)

			assert.stub(LpdbPlacementStore).was_not.called()
		end)

		it('processes multiple participants', function()
			local args = {
				{
					'team liquid',
					players = {{'player1'}},
				},
				{
					'bds',
					players = {{'player2'}},
				},
			}

			TeamParticipantsController.fromTemplate(args)

			assert.stub(LpdbPlacementStore).was.called(2)
			assert.is_truthy(LpdbPlacementStore.calls[1].vals[1]:find('team liquid'))
			assert.is_truthy(LpdbPlacementStore.calls[2].vals[1]:find('bds'))
		end)
	end)
end)

describe('Team Participants Parser', function()
	local TeamParticipantsWikiParser
	local Table

	before_each(function()
		TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')
		Table = require('Module:Table')
	end)

	-- Helper to create a minimal valid participant input for testing.
	local function createBasicParticipantInput(overrides)
		return Table.merge({
			'team liquid',
			players = {
				{'player1'},
			}
		}, overrides or {})
	end

	describe('parseWikiInput', function()
		insulate('parses array of participant inputs', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('parses multiple participants', function()
				local args = {
					createBasicParticipantInput({[1] = 'team liquid'}),
					createBasicParticipantInput({[1] = 'bds'}),
					createBasicParticipantInput({[1] = 'mouz'}),
				}

				local result = TeamParticipantsWikiParser.parseWikiInput(args)

				assert.are_equal(3, #result.participants)
				assert.are_equal('team', result.participants[1].opponent.type)
			end)

			it('parses date from args.date', function()
				local args = {
					createBasicParticipantInput(),
					date = '2024-06-15',
				}

				local result = TeamParticipantsWikiParser.parseWikiInput(args)

				local date = result.participants[1].date
				assert.are_equal(2024, date.year)
				assert.are_equal(6, date.month)
				assert.are_equal(15, date.day)
			end)
		end)
	end)

	describe('parseParticipant', function()
		insulate('parseParticipant behavior', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('parses and assigns players', function()
				local input = {
					'team liquid',
					players = {
						{'player1', flag = 'us'},
						{'player2', flag = 'ca'},
					}
				}

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal(2, #result.opponent.players)
				assert.are_equal('player1', result.opponent.players[1].displayName)
				assert.are_equal('player2', result.opponent.players[2].displayName)
			end)

			it('parses contenders into TBD opponent with potentialQualifiers', function()
				local input = {
					contenders = {'team liquid', 'bds', 'mouz'}
				}

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('tbd', result.opponent.template)
				assert.are_equal(3, #result.potentialQualifiers)
				assert.are_equal('team liquid', result.potentialQualifiers[1].template)
				assert.are_equal('bds', result.potentialQualifiers[2].template)
				assert.are_equal('mouz', result.potentialQualifiers[3].template)
			end)

			it('generates warnings for invalid contenders', function()
				local input = {
					contenders = 'not a table'
				}

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal(1, #result.warnings)
				assert.matches('Invalid contenders: expected a list of non%-empty strings', result.warnings[1])
			end)

			it('preserves highlighted flag', function()
				local input = createBasicParticipantInput({
					notes = {
						{'Important Note', highlighted = true},
						{'Regular Note', highlighted = false},
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_true(result.notes[1].highlighted)
				assert.is_false(result.notes[2].highlighted)
			end)

			it('filters out notes with missing text', function()
				local input = createBasicParticipantInput({
					notes = {
						{'Valid Note'},
						{highlighted = true},
						{'Another Valid Note'},
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal(2, #result.notes)
				assert.are_equal('Valid Note', result.notes[1].text)
				assert.are_equal('Another Valid Note', result.notes[2].text)
			end)

			it('sets shouldImportFromDb=true when import=true', function()
				local input = createBasicParticipantInput({
					import = true,
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_true(result.shouldImportFromDb)
			end)

			it('sets shouldImportFromDb=false by default', function()
				local input = createBasicParticipantInput()

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_false(result.shouldImportFromDb)
			end)
		end)
	end)

	describe('parsePlayer', function()
		insulate('player extradata fields', function()
			it('parses trophies as number', function()
				local result = TeamParticipantsWikiParser.parsePlayer({'PlayerName', trophies = '3'})

				assert.are_equal(3, result.extradata.trophies)
			end)

			it('normalizes type to player/staff only', function()
				local defaultResult = TeamParticipantsWikiParser.parsePlayer({'PlayerName'})
				local staffResult = TeamParticipantsWikiParser.parsePlayer({'CoachName', type = 'staff'})
				-- 'sub' is not a type; it is tracked via extradata.status and the type stays 'player'
				local subResult = TeamParticipantsWikiParser.parsePlayer({'SubName', type = 'sub'})

				assert.are_equal('player', defaultResult.extradata.type)
				assert.are_equal('staff', staffResult.extradata.type)
				assert.are_equal('player', subResult.extradata.type)
			end)
		end)
	end)

	describe('Qualification Parsing', function()
		insulate('qualification method parsing', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('parses invite qualification method', function()
				local input = createBasicParticipantInput({
					qualification = {method = 'invite', text = 'Direct Invite'}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('invite', result.qualification.method)
			end)

			it('returns nil when method is missing', function()
				local input = createBasicParticipantInput({
					qualification = {
						text = 'No Method',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_nil(result.qualification)
			end)
		end)

		insulate('qualification type detection and validation', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('detects tournament type and attaches tournament data', function()
				local Tournament = require('Module:Tournament')
				local TournamentGetStub = stub(Tournament, 'getTournament')
				TournamentGetStub.returns({
					pageName = 'Test/Tournament',
					displayName = 'Test Tournament',
					icon = 'Test.png',
					iconDark = 'Test_dark.png',
				})

				local input = createBasicParticipantInput({
					qualification = {method = 'qual', page = 'Test/Tournament'}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('tournament', result.qualification.type)
				assert.is_table(result.qualification.tournament)
				assert.are_equal('Test/Tournament', result.qualification.tournament.pageName)
				assert.are_equal('Test Tournament', result.qualification.tournament.displayName)

				TournamentGetStub:revert()
			end)

			it('detects external type and preserves url', function()
				local input = createBasicParticipantInput({
					qualification = {method = 'qual', url = 'https://example.com', text = 'External'}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('external', result.qualification.type)
				assert.are_equal('https://example.com', result.qualification.url)
			end)

			it('detects other type for text-only qualifications', function()
				local input = createBasicParticipantInput({
					qualification = {method = 'qual', text = 'Other Qualifier'}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('other', result.qualification.type)
			end)

			it('requires text for external qualifiers', function()
				local input = createBasicParticipantInput({
					qualification = {method = 'qual', url = 'https://example.com'}
				})

				assert.has_error(function()
					TeamParticipantsWikiParser.parseParticipant(input, os.time())
				end, 'External or non-tournament qualifier must have text')
			end)
		end)
	end)
end)
