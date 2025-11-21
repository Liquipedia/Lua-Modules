--- Triple Comment to Enable our LLS Plugin
describe('Team Participants TBD Functionality', function()
	local TeamParticipantsWikiParser
	local TeamParticipantsController
	local Array

	before_each(function()
		TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')
		TeamParticipantsController = require('Module:TeamParticipants/Controller')
		Array = require('Module:Array')
	end)

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
			local actualPlayers = Array.filter(opponent.players, function(p)
				return p.extradata.type == 'player'
			end)
			assert.are_equal(5, #actualPlayers)
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
		local actualPlayers = Array.filter(opponent.players, function(p)
			return p.extradata.type == 'player'
		end)

		assert.are_equal(5, #actualPlayers)
			assert.are_equal('alexis', actualPlayers[1].displayName)
			assert.are_equal('TBD', actualPlayers[4].displayName)
			assert.are_equal('TBD', actualPlayers[5].displayName)

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
