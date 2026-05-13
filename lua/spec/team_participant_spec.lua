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
