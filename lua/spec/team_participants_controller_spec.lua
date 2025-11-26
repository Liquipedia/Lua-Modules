--- Triple Comment to Enable our LLS Plugin
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
								nationality = 'ca',
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

			it('returns squad members for valid team', function()
				local participant = {
					opponent = {template = 'team liquid'},
					date = os.time(),
				}

				local result = TeamParticipantsController.importSquadMembersFromDatabase(participant)

				assert.is_not_nil(result)
				assert.are_equal(3, #result)
			end)

			it('filters by player type', function()
				local participant = {
					opponent = {template = 'team liquid'},
					date = os.time(),
				}

				local result = TeamParticipantsController.importSquadMembersFromDatabase(participant)

				local playerCount = #Array.filter(result, function(member)
					return member.extradata.type == 'player'
				end)
				assert.are_equal(2, playerCount)
			end)

			it('auto-imports coach staff roles', function()
				local participant = {
					opponent = {template = 'team liquid'},
					date = os.time(),
				}

				local result = TeamParticipantsController.importSquadMembersFromDatabase(participant)

				local coachCount = #Array.filter(result, function(member)
					return member.extradata.type == 'staff'
				end)
				assert.are_equal(1, coachCount)
			end)

			it('returns nil when team is not found', function()
				local participant = {
					opponent = {template = 'nonexistent team'},
					date = os.time(),
				}

				local result = TeamParticipantsController.importSquadMembersFromDatabase(participant)

				assert.is_nil(result)
			end)
		end)

		insulate('handles former players and substitutes', function()
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
								nationality = 'ca',
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

			it('converts substitute role to type=sub', function()
				local participant = {
					opponent = {template = 'team liquid'},
					date = os.time(),
				}

				local result = TeamParticipantsController.importSquadMembersFromDatabase(participant)

				local subs = Array.filter(result, function(member)
					return member.extradata.type == 'sub'
				end)
				assert.are_equal(1, #subs)
				assert.are_equal('SubPlayer', subs[1].displayName)
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
							nationality = 'ca',
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
		it('appends new imported players to manual list', function()
			local manualPlayers = {
				{displayName = 'ManualPlayer1', pageName = 'ManualPlayer1', extradata = {type = 'player'}},
			}
			local importedPlayers = {
				{displayName = 'ImportedPlayer1', pageName = 'ImportedPlayer1', extradata = {type = 'player'}},
				{displayName = 'ImportedPlayer2', pageName = 'ImportedPlayer2', extradata = {type = 'player'}},
			}

			TeamParticipantsController.mergeManualAndImportedPlayers(manualPlayers, importedPlayers)

			assert.are_equal(3, #manualPlayers)
			assert.are_equal('ManualPlayer1', manualPlayers[1].pageName)
			assert.are_equal('ImportedPlayer1', manualPlayers[2].pageName)
			assert.are_equal('ImportedPlayer2', manualPlayers[3].pageName)
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
			assert.are_equal('us', manualPlayers[1].flag)
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

		it('handles empty imported array', function()
			local manualPlayers = {
				{displayName = 'Player1', pageName = 'Player1', extradata = {type = 'player'}},
			}
			local importedPlayers = {}

			TeamParticipantsController.mergeManualAndImportedPlayers(manualPlayers, importedPlayers)

			assert.are_equal(1, #manualPlayers)
		end)

		it('handles empty manual array', function()
			local manualPlayers = {}
			local importedPlayers = {
				{displayName = 'ImportedPlayer1', pageName = 'ImportedPlayer1', extradata = {type = 'player'}},
			}

			TeamParticipantsController.mergeManualAndImportedPlayers(manualPlayers, importedPlayers)

			assert.are_equal(1, #manualPlayers)
			assert.are_equal('ImportedPlayer1', manualPlayers[1].pageName)
		end)

		it('matches players by pageName', function()
			local manualPlayers = {
				{displayName = 'DisplayName1', pageName = 'PageName1', extradata = {type = 'player'}},
			}
			local importedPlayers = {
				{displayName = 'DifferentDisplay', pageName = 'PageName1', extradata = {type = 'sub'}},
			}

			TeamParticipantsController.mergeManualAndImportedPlayers(manualPlayers, importedPlayers)

			assert.are_equal(1, #manualPlayers)
			assert.are_equal('DisplayName1', manualPlayers[1].displayName)
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

			local originalCount = #parsedData.participants[1].opponent.players

			TeamParticipantsController.importParticipants(parsedData)

			assert.are_equal(originalCount, #parsedData.participants[1].opponent.players)
		end)

		it('does not create players array when it does not exist', function()
			local parsedData = {
				participants = {
					{
						opponent = {
							template = 'team liquid',
						},
						shouldImportFromDb = true,
					}
				}
			}

			TeamParticipantsController.importParticipants(parsedData)

			assert.is_nil(parsedData.participants[1].opponent.players)
		end)

		insulate('calls import and merge for valid participants', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function(entity)
					if entity == 'squadplayer' then
						return {
							createSquadMember({
								id = 'ImportedPlayer',
								link = 'ImportedPlayer',
								name = 'Imported Player',
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

			it('imports and merges players', function()
				local parsedData = {
					participants = {
						{
							opponent = {
								template = 'team liquid',
								players = {
									{displayName = 'ManualPlayer', pageName = 'ManualPlayer', extradata = {type = 'player'}},
								}
							},
							shouldImportFromDb = true,
							date = os.time(),
						}
					}
				}

				TeamParticipantsController.importParticipants(parsedData)

				assert.are_equal(2, #parsedData.participants[1].opponent.players)
				assert.are_equal('ManualPlayer', parsedData.participants[1].opponent.players[1].displayName)
				assert.are_equal('ImportedPlayer', parsedData.participants[1].opponent.players[2].displayName)
			end)
		end)

		it('mutates parsedData structure correctly', function()
			local parsedData = {
				participants = {
					{
						opponent = {
							template = 'team liquid',
							players = {}
						},
						shouldImportFromDb = false,
					}
				}
			}

			TeamParticipantsController.importParticipants(parsedData)

			assert.is_table(parsedData.participants)
			assert.is_table(parsedData.participants[1].opponent.players)
		end)
	end)

	describe('fillIncompleteRosters', function()
		it('skips TBD opponents', function()
			local parsedData = {
				participants = {
					{
						opponent = {
							template = 'tbd',
							players = {}
						}
					}
				},
				expectedPlayerCount = 5,
			}

			TeamParticipantsController.fillIncompleteRosters(parsedData)

			assert.are_equal(0, #parsedData.participants[1].opponent.players)
		end)

		it('fills rosters for non-TBD teams', function()
			local parsedData = {
				participants = {
					{
						opponent = {
							template = 'team liquid',
							players = {
								{displayName = 'Player1', extradata = {type = 'player'}},
								{displayName = 'Player2', extradata = {type = 'player'}},
							}
						}
					}
				},
				expectedPlayerCount = 5,
			}

			TeamParticipantsController.fillIncompleteRosters(parsedData)

			assert.are_equal(5, #parsedData.participants[1].opponent.players)
			assert.are_equal('Player1', parsedData.participants[1].opponent.players[1].displayName)
			assert.are_equal('TBD', parsedData.participants[1].opponent.players[3].displayName)
		end)

		it('passes expectedPlayerCount correctly', function()
			local parsedData = {
				participants = {
					{
						opponent = {
							template = 'team liquid',
							players = {
								{displayName = 'Player1', extradata = {type = 'player'}},
							}
						}
					}
				},
				expectedPlayerCount = 3,
			}

			TeamParticipantsController.fillIncompleteRosters(parsedData)

			local playerCount = #Array.filter(parsedData.participants[1].opponent.players, function(p)
				return p.extradata.type == 'player'
			end)
			assert.are_equal(3, playerCount)
		end)

		it('mutates parsedData.participants', function()
			local parsedData = {
				participants = {
					{
						opponent = {
							template = 'team liquid',
							players = {}
						}
					}
				},
				expectedPlayerCount = 2,
			}

			local originalRef = parsedData.participants[1]

			TeamParticipantsController.fillIncompleteRosters(parsedData)

			assert.are_equal(originalRef, parsedData.participants[1])
			assert.are_equal(2, #parsedData.participants[1].opponent.players)
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

			assert.stub(LpdbPlacementStore).was.called(0)
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

			assert.stub(LpdbPlacementStore).was.called(1)
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

			assert.stub(LpdbPlacementStore).was.called(0)
		end)

		it('page variables are set for participants', function()
			local args = {
				{
					'team liquid',
					players = {
						{'player1'},
					}
				},
			}

			TeamParticipantsController.fromTemplate(args)

			local teamVar = Variables.varDefault('Team Liquid_p1')
			assert.are_equal('player1', teamVar)
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
