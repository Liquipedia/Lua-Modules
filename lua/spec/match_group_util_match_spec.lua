--- Triple Comment to Enable our LLS Plugin

--- The fixtures below name only the fields each test is about, rather than whole records.
---@diagnostic disable: missing-fields

--[[
Tests for Module:MatchGroup/Util/Match, the match model: reading match records into matches,
opponents, games and players.
]]

--- Casts a partial record to a match2 record, so a test only has to name the fields it cares about.
---@param record table
---@return match2
local function matchRecord(record)
	return record
end

--- Casts a partial record to a match2game record.
---@param record table
---@return match2game
local function gameRecord(record)
	return record
end

insulate('MatchGroup/Util/Match', function()
	describe('matchFromRecord', function()
		it('reads a full bracket match record', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local match = MatchUtil.matchFromRecord(matchRecord{
				match2id = 'abcdefghij_R01-M001',
				bestof = '3',
				date = '2022-01-05 12:00:00',
				dateexact = '1',
				finished = '1',
				winner = '1',
				mode = 'team',
				pagename = 'Some/Page',
				tournament = 'Some Tournament',
				extradata = {comment = 'a comment', timestamp = 1641384000, timezoneid = 'CET'},
				match2bracketdata = {type = 'bracket', header = 'Semifinals'},
				match2opponents = {
					{name = 'Team A', score = '2', status = 'S', type = 'team', match2players = {}},
					{name = 'Team B', score = '1', status = 'S', type = 'team', match2players = {}},
				},
				match2games = {{map = 'Map1', winner = '1'}},
			})

			assert.are_equal('abcdefghij_R01-M001', match.matchId)
			assert.are_equal(3, match.bestof)
			assert.are_equal('2022-01-05 12:00:00', match.date)
			assert.is_true(match.dateIsExact)
			assert.is_true(match.finished)
			assert.are_equal(1, match.winner)
			assert.are_equal('Some/Page', match.pageName)
			assert.are_equal('Some Tournament', match.tournament)
			assert.are_equal(2, #match.opponents)
			assert.are_equal(1, #match.games)
			assert.are_equal('finished', match.phase)
			assert.are_equal('bracket', match.bracketData.type)
		end)

		it('lifts comment, timestamp and timezone out of extradata', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local match = MatchUtil.matchFromRecord(matchRecord{
				date = '2022-01-05',
				mode = 'team',
				extradata = {comment = 'a comment', timestamp = 1641384000, timezoneid = 'CET', keepme = 'yes'},
				match2opponents = {},
				match2games = {},
			})

			assert.are_equal('a comment', match.comment)
			assert.are_equal(1641384000, match.timestamp)
			assert.are_equal('CET', match.timezoneId)
			-- the lifted keys are removed from extradata, anything else stays
			assert.are_same({keepme = 'yes'}, match.extradata)
		end)

		it('fills in the defaults of a minimal record', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local match = MatchUtil.matchFromRecord(matchRecord{
				date = '2022-01-05',
				mode = 'team',
				match2opponents = {},
				match2games = {},
			})

			assert.are_equal(0, match.bestof)
			assert.is_false(match.dateIsExact)
			assert.is_false(match.finished)
			assert.are_same({}, match.links)
			assert.are_same({}, match.stream)
			assert.are_same({}, match.extradata)
			assert.are_same({}, match.bracketData)
			-- an unset type falls back to 'literal', not to nil
			assert.are_equal('literal', match.type)
			assert.is_nil(match.winner)
		end)

		it('lower cases the walkover and blanks out empty strings', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local match = MatchUtil.matchFromRecord(matchRecord{
				date = '2022-01-05',
				mode = 'team',
				walkover = 'FF',
				icon = '',
				vod = '',
				resulttype = '',
				match2opponents = {},
				match2games = {},
			})

			assert.are_equal('ff', match.walkover)
			assert.is_nil(match.icon)
			assert.is_nil(match.vod)
			assert.is_nil(match.resultType)
		end)

		it('parses json encoded links, stream and bracket data', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local match = MatchUtil.matchFromRecord(matchRecord{
				date = '2022-01-05',
				mode = 'team',
				links = '{"twitch":"https://twitch.tv/x"}',
				stream = '{"twitch":"x"}',
				match2bracketdata = '{"type":"matchlist","header":"Round 1"}',
				match2opponents = {},
				match2games = {},
			})

			assert.are_same({twitch = 'https://twitch.tv/x'}, match.links)
			assert.are_same({twitch = 'x'}, match.stream)
			assert.are_equal('Round 1', match.bracketData.header)
		end)

		it('auto assigns lower edges for bracket matches that have none', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local match = MatchUtil.matchFromRecord(matchRecord{
				date = '2022-01-05',
				mode = 'team',
				match2bracketdata = {type = 'bracket', toupper = 'R02-M001', tolower = 'R02-M002'},
				match2opponents = {
					{name = 'A', match2players = {}},
					{name = 'B', match2players = {}},
				},
				match2games = {},
			})

			assert.are_same({'R02-M001', 'R02-M002'}, match.bracketData.lowerMatchIds)
			assert.are_same({
				{lowerMatchIndex = 1, opponentIndex = 1},
				{lowerMatchIndex = 2, opponentIndex = 2},
			}, match.bracketData.lowerEdges)
		end)
	end)

	describe('opponentFromRecord', function()
		---@param opponent table
		---@param matchOverrides table?
		---@return standardOpponent
		local function readOpponent(opponent, matchOverrides)
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local record = matchRecord(require('Module:Table').merge(
				{match2opponents = {opponent}, match2games = {}},
				matchOverrides or {}
			))
			return MatchUtil.opponentFromRecord(record, record.match2opponents[1], 1)
		end

		it('reads the scores, placement and template', function()
			local opponent = readOpponent{
				name = 'Team A',
				score = '2',
				status = 'S',
				placement = '1',
				template = 'team a',
				type = 'team',
				icon = 'Icon.png',
				match2players = {},
			}

			assert.are_equal('Team A', opponent.name)
			assert.are_equal(2, opponent.score)
			assert.are_equal('S', opponent.status)
			assert.are_equal(1, opponent.placement)
			assert.are_equal('team a', opponent.template)
			assert.are_equal('team', opponent.type)
			assert.are_equal('Icon.png', opponent.icon)
			assert.is_nil(opponent.scoreDisplay)
		end)

		it('lifts the advance background and flag out of extradata', function()
			local opponent = readOpponent{
				name = 'Team A',
				extradata = {bg = 'up', advances = 'true', keepme = 'yes'},
				match2players = {},
			}

			assert.are_equal('up', opponent.advanceBg)
			assert.is_true(opponent.advances)
			assert.are_same({keepme = 'yes'}, opponent.extradata)
		end)

		it('falls back to a literal opponent with no score', function()
			local opponent = readOpponent{match2players = {}}
			assert.are_equal('literal', opponent.type)
			assert.is_nil(opponent.name)
			assert.is_nil(opponent.score)
			assert.are_same({}, opponent.players)
		end)
	end)

	describe('createOpponent', function()
		it('fills in the defaults of a bare opponent', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			assert.are_same({
				extradata = {},
				players = {},
				type = 'literal',
			}, MatchUtil.createOpponent{})
		end)

		it('passes the given fields through', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local opponent = MatchUtil.createOpponent{name = 'A', score = 2, type = 'team', template = 'a'}
			assert.are_equal('A', opponent.name)
			assert.are_equal(2, opponent.score)
			assert.are_equal('team', opponent.type)
			assert.are_equal('a', opponent.template)
		end)
	end)

	describe('playerFromRecord', function()
		it('reads a player and pulls the team out of extradata', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local player = MatchUtil.playerFromRecord{
				name = 'Player_A',
				displayname = 'pA',
				flag = 'se',
				extradata = {playerteam = 'Team A', keepme = 'yes'},
			}

			assert.are_equal('Player_A', player.pageName)
			assert.are_equal('pA', player.displayName)
			assert.are_equal('se', player.flag)
			assert.are_equal('Team A', player.team)
			assert.are_same({keepme = 'yes'}, player.extradata)
		end)

		it('blanks out an empty flag', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			assert.is_nil(MatchUtil.playerFromRecord{name = 'A', flag = ''}.flag)
		end)
	end)

	describe('gameFromRecord', function()
		it('reads a game and lifts its display fields out of extradata', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local game = MatchUtil.gameFromRecord(gameRecord{
				map = 'Map1',
				winner = '1',
				subgroup = '2',
				scores = '[1,0]',
				length = '30:00',
				mode = '1v1',
				walkover = 'FF',
				extradata = {
					header = 'Game 1',
					displayname = 'Pretty Map',
					comment = 'gg',
					dateexact = '1',
					timestamp = 1641384000,
					timezoneid = 'CET',
					keepme = 'yes',
				},
			}, 2)

			assert.are_equal('Map1', game.map)
			assert.are_equal('Pretty Map', game.mapDisplayName)
			assert.are_equal('Game 1', game.header)
			assert.are_equal('gg', game.comment)
			assert.are_equal(1, game.winner)
			assert.are_equal(2, game.subgroup)
			assert.are_same({1, 0}, game.scores)
			assert.are_equal('30:00', game.length)
			assert.are_equal('ff', game.walkover)
			assert.are_equal(1641384000, game.timestamp)
			assert.are_equal('CET', game.timezoneId)
			assert.are_same({keepme = 'yes'}, game.extradata)
		end)

		it('defaults the scores to an empty list', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			assert.are_same({}, MatchUtil.gameFromRecord(gameRecord{map = 'Map1'}, 2).scores)
		end)
	end)

	describe('record extradata', function()
		it('parses json encoded extradata', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local match = MatchUtil.matchFromRecord(matchRecord{
				date = '2022-01-05',
				mode = 'team',
				extradata = '{"a":"b"}',
				match2opponents = {},
				match2games = {},
			})
			assert.are_same({a = 'b'}, match.extradata)
		end)

		it('does not mutate the extradata of the record it was given', function()
			-- the model lifts comment/timestamp/timezoneid out of extradata, so it has to work on a copy
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local extradata = {comment = 'a comment', timestamp = 1641384000, keepme = 'yes'}
			local match = MatchUtil.matchFromRecord(matchRecord{
				date = '2022-01-05',
				mode = 'team',
				extradata = extradata,
				match2opponents = {},
				match2games = {},
			})

			assert.are_equal('a comment', match.comment)
			assert.are_same({keepme = 'yes'}, match.extradata)
			assert.are_same({comment = 'a comment', timestamp = 1641384000, keepme = 'yes'}, extradata)
		end)

		it('defaults to an empty table when the record has none', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local match = MatchUtil.matchFromRecord(matchRecord{
				date = '2022-01-05', mode = 'team', match2opponents = {}, match2games = {},
			})
			assert.are_same({}, match.extradata)
		end)
	end)

	describe('groupBySubgroup', function()
		it('groups consecutive games with the same subgroup and takes their headers', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local submatches = MatchUtil.groupBySubgroup{
				extradata = {subgroup1header = 'First', subgroup2header = 'Second'},
				games = {
					{map = 'M1', subgroup = 1},
					{map = 'M2', subgroup = 1},
					{map = 'M3', subgroup = 2},
				},
			}

			assert.are_equal(2, #submatches)
			assert.are_equal(2, #submatches[1].games)
			assert.are_equal('First', submatches[1].header)
			assert.are_equal(1, submatches[1].subgroup)
			assert.are_equal(1, #submatches[2].games)
			assert.are_equal('Second', submatches[2].header)
		end)

		it('numbers the submatches by position, not by the subgroup value', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local submatches = MatchUtil.groupBySubgroup{
				extradata = {},
				games = {{map = 'M1', subgroup = 5}, {map = 'M2', subgroup = 9}},
			}

			assert.are_equal(1, submatches[1].subgroup)
			assert.are_equal(2, submatches[2].subgroup)
		end)

		it('starts a new submatch every time the subgroup changes back', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local submatches = MatchUtil.groupBySubgroup{
				extradata = {},
				games = {{subgroup = 1}, {subgroup = 2}, {subgroup = 1}},
			}
			assert.are_equal(3, #submatches)
		end)

		it('returns nothing for a match without games', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			assert.are_same({}, MatchUtil.groupBySubgroup{extradata = {}, games = {}})
		end)
	end)

	describe('computeMatchPhase', function()
		it('is finished once there is a winner or the finished flag is set', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			assert.are_equal('finished', MatchUtil.computeMatchPhase{winner = 1, date = '2099-01-01'})
			assert.are_equal('finished', MatchUtil.computeMatchPhase{finished = true, date = '2099-01-01'})
		end)

		it('is ongoing once an exact start time has passed', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			assert.are_equal('ongoing',
				MatchUtil.computeMatchPhase{date = '2020-01-01 12:00:00', dateIsExact = true})
		end)

		it('is upcoming before the start time', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			assert.are_equal('upcoming',
				MatchUtil.computeMatchPhase{date = '2099-01-01 12:00:00', dateIsExact = true})
		end)

		it('is upcoming when the date is explicitly not exact', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			assert.are_equal('upcoming',
				MatchUtil.computeMatchPhase{date = '2020-01-01 12:00:00', dateexact = '0'})
		end)

		it('ignores a dateIsExact of false, because it is read with an or', function()
			-- `match.dateIsExact or match.dateexact` turns a false into a nil, which is not the same as
			-- an explicit false, so a past match with dateIsExact = false still counts as ongoing
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			assert.are_equal('ongoing',
				MatchUtil.computeMatchPhase{date = '2020-01-01 12:00:00', dateIsExact = false})
		end)

		it('is upcoming when there is no usable date', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			assert.are_equal('upcoming', MatchUtil.computeMatchPhase{})
		end)

		it('accepts a raw record as well as a model, via dateexact and timestamp', function()
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			assert.are_equal('ongoing',
				MatchUtil.computeMatchPhase{dateexact = '1', timestamp = 1577880000})
		end)
	end)
end)

--[[
Reading map scores onto the opponent instead of the match score is per wiki configuration,
so it needs a wiki that turns it on.
]]
insulate('MatchGroup/Util/Match on a wiki with game scores in a best of one', function()
	setup(function() SetActiveWiki('counterstrike') end)
	teardown(function() SetActiveWiki() end)

	---@param record table
	---@return standardOpponent
	local function readFirstOpponent(record)
		local MatchUtil = require('Module:MatchGroup/Util/Match')
		return MatchUtil.opponentFromRecord(record, record.match2opponents[1], 1)
	end

	it('shows the map score of a best of one', function()
		local opponent = readFirstOpponent{
			bestof = '1',
			match2opponents = {
				{name = 'A', score = '1', status = 'S', match2players = {}},
				{name = 'B', score = '0', status = 'S', match2players = {}},
			},
			match2games = {{opponents = {{score = '16', status = 'S'}, {score = '14', status = 'S'}}}},
		}

		-- the match score stays, the map score is offered alongside it for display
		assert.are_equal(1, opponent.score)
		assert.are_equal(16, opponent.scoreDisplay)
		assert.are_equal('S', opponent.status)
	end)

	it('leaves longer series alone', function()
		local opponent = readFirstOpponent{
			bestof = '3',
			match2opponents = {
				{name = 'A', score = '2', status = 'S', match2players = {}},
				{name = 'B', score = '1', status = 'S', match2players = {}},
			},
			match2games = {{opponents = {{score = '16'}, {score = '14'}}}},
		}
		assert.is_nil(opponent.scoreDisplay)
	end)

	it('leaves a best of one alone when an opponent did not simply score', function()
		local opponent = readFirstOpponent{
			bestof = '1',
			match2opponents = {
				{name = 'A', score = '1', status = 'S', match2players = {}},
				{name = 'B', score = '-1', status = 'FF', match2players = {}},
			},
			match2games = {{opponents = {{score = '16'}, {score = '0'}}}},
		}
		assert.is_nil(opponent.scoreDisplay)
	end)
end)
