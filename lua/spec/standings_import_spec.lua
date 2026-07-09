--- Triple Comment to Enable our LLS Plugin
local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

describe('Standings import from matches', function()
	local StandingsParseLpdb = require('Module:Standings/Parse/Lpdb')
	local Array = require('Module:Array')

	---@param props {matchId: string, opponents: {template: string, name: string, score: integer,
	---placement: integer}[], winner: integer?, finished: boolean?}
	---@return table
	local function match2Record(props)
		return {
			match2id = props.matchId,
			date = '2024-01-05',
			dateexact = '1',
			finished = props.finished ~= false and '1' or '0',
			winner = props.winner and tostring(props.winner) or '',
			bestof = '3',
			extradata = {},
			match2bracketdata = {},
			match2games = {},
			match2opponents = Array.map(props.opponents, function(opponentSpec)
				return {
					type = opponentSpec.type or 'team',
					template = opponentSpec.template,
					name = opponentSpec.name,
					score = opponentSpec.score,
					status = 'S',
					placement = opponentSpec.placement,
					extradata = {},
					match2players = {},
				}
			end),
		}
	end

	local function stubMatchQuery(records)
		local recordsById = {}
		for _, record in ipairs(records) do
			recordsById[record.match2id] = record
		end
		return stub(mw.ext.LiquipediaDB, 'lpdb', function(tableName, parameters)
			if tableName ~= 'match2' then
				return {}
			end
			-- return the records the conditions ask for, mimicking the LPDB matchid filter
			local found = {}
			for matchId, record in pairs(recordsById) do
				if parameters.conditions:find(matchId, 1, true) then
					table.insert(found, record)
				end
			end
			return found
		end)
	end

	local function swissScoreMapper(opponent)
		return opponent.placement == 1 and 1 or 0
	end

	local function findOpponent(opponents, name)
		return Array.find(opponents, function(opponentData)
			return opponentData.opponent.name == name
		end)
	end

	before_each(function()
		TeamTemplateMock.setUp()
	end)

	after_each(function()
		TeamTemplateMock.tearDown()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb:revert()
	end)

	it('returns no opponents without matches', function()
		stubMatchQuery{}
		assert.are_same({}, StandingsParseLpdb.importFromMatches({{roundNumber = 1, matches = {}}}, swissScoreMapper))
	end)

	it('builds opponents with per round scoreboards and accumulated matches', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'tt9 esports 2022', name = 'TT9 Esports', score = 0, placement = 2},
			}},
			match2Record{matchId = 'M2', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 1, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
			{roundNumber = 2, matches = {'M2'}},
		}, swissScoreMapper)

		assert.are_equal(3, #opponents)

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_equal(1, heroic.rounds[1].scoreboard.points)
		assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
		assert.are_equal('M1', heroic.rounds[1].matchId)
		assert.are_equal('', heroic.rounds[1].specialstatus)
		assert.are_equal(1, #heroic.rounds[1].matches)

		assert.are_equal(1, heroic.rounds[2].scoreboard.points)
		assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[2].scoreboard.match)
		assert.are_equal('M2', heroic.rounds[2].matchId)
		-- matches accumulate over rounds
		assert.are_equal(2, #heroic.rounds[2].matches)
		assert.are_equal('M1', heroic.rounds[2].matches[1].matchId)
		assert.are_equal('M2', heroic.rounds[2].matches[2].matchId)

		local tt9 = findOpponent(opponents, 'TT9 Esports')
		assert.are_equal(0, tt9.rounds[1].scoreboard.points)
		assert.are_same({w = 0, d = 0, l = 1}, tt9.rounds[1].scoreboard.match)
		-- TT9 did not play round 2
		assert.are_equal('nc', tt9.rounds[2].specialstatus)
		assert.is_nil(tt9.rounds[2].matchId)

		local wolves = findOpponent(opponents, 'Wolves Esports')
		assert.are_equal('nc', wolves.rounds[1].specialstatus)
		assert.are_same({w = 0, d = 0, l = 1}, wolves.rounds[2].scoreboard.match)
	end)

	it('does not count unfinished matches in the match scoreboard', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', finished = false, opponents = {
				{template = 'heroic', name = 'Heroic', score = 1, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 1, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
		}, swissScoreMapper)

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_same({w = 0, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
		assert.are_equal('M1', heroic.rounds[1].matchId)
	end)

	it('counts draws when the match has no winner', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 0, opponents = {
				{template = 'heroic', name = 'Heroic', score = 1, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 1, placement = 1},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
		}, swissScoreMapper)

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_same({w = 0, d = 1, l = 0}, heroic.rounds[1].scoreboard.match)
	end)

	it('counts a match in every round it is assigned to', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 0, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
			{roundNumber = 2, matches = {'M1'}},
		}, swissScoreMapper)

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
		assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[2].scoreboard.match)
	end)

	it('drops tbd opponents', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'tbd', name = 'TBD', score = 0, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
		}, swissScoreMapper)

		assert.are_equal(1, #opponents)
		assert.are_equal('Heroic', opponents[1].opponent.name)
	end)

	it('applies a points based score mapper', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 13, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 7, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
		}, function(opponent)
			if opponent.status == 'S' then
				return tonumber(opponent.score)
			end
			return nil
		end)

		assert.are_equal(13, findOpponent(opponents, 'Heroic').rounds[1].scoreboard.points)
		assert.are_equal(7, findOpponent(opponents, 'Wolves Esports').rounds[1].scoreboard.points)
	end)
end)
