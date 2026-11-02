--- Triple Comment to Enable our LLS Plugin
describe('Standings Table from template', function()
	local StandingsTable = require('Module:Standings/Table')

	before_each(function()
		stub(mw.ext.LiquipediaDB, 'lpdb', {})
		stub(mw.ext.LiquipediaDB, 'lpdb_standingstable')
		stub(mw.ext.LiquipediaDB, 'lpdb_standingsentry')
	end)

	after_each(function()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb:revert()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb_standingstable:revert()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb_standingsentry:revert()
	end)

	it('renders group standings', function()
		local html = tostring(StandingsTable.fromTemplate{
			tabletype = 'group',
			title = 'Group A',
			import = 'false',
			round1 = {title = 'Week 1', started = 'true', finished = 'true'},
			round2 = {title = 'Week 2', started = 'true', finished = 'false'},
			{type = 'literal', name = 'Alpha', r1 = '3', r2 = '0'},
			{type = 'literal', name = 'Bravo', r1 = '1', r2 = '3'},
		})
		assert.is_truthy(html:find('standings-group', 1, true))
		assert.is_truthy(html:find('Group A', 1, true))
		assert.is_truthy(html:find('>Week 1<', 1, true))
		---@diagnostic disable-next-line: undefined-field
		local storedTable = mw.ext.LiquipediaDB.lpdb_standingstable.calls[1].vals[2]
		assert.are_equal('league', storedTable.type)
	end)

	it('applies the width to the table', function()
		local html = tostring(StandingsTable.fromTemplate{
			tabletype = 'group',
			import = 'false',
			width = '600px',
			round1 = {started = 'true', finished = 'true'},
			{type = 'literal', name = 'Alpha', r1 = '3'},
		})
		assert.is_truthy(html:find('class="table2[^"]*standings%-group"[^>]*style="width:600px"'))
	end)

	describe('imported match columns', function()
		local function queriesGames(args)
			StandingsTable.fromTemplate(args)
			---@diagnostic disable-next-line: undefined-field
			local matchQuery = mw.ext.LiquipediaDB.lpdb.calls[1]
			assert.are_equal('match2', matchQuery.vals[1])
			return matchQuery.vals[2].query:find('match2games', 1, true) ~= nil
		end

		it('leaves out the games when no tiebreaker reads them', function()
			assert.is_false(queriesGames{
				tabletype = 'swiss',
				round1 = {matches = 'M1'},
				tiebreakers = '["points", "gamediff", "buchholz"]',
			})
		end)

		it('includes the games for a tiebreaker that reads them', function()
			assert.is_true(queriesGames{
				tabletype = 'swiss',
				round1 = {matches = 'M1'},
				tiebreakers = '["points", "rounddiff"]',
			})
		end)

		it('includes the games with overtime', function()
			local Info = require('Module:Info')
			local originalStandingsConfig = Info.config.standings
			Info.config.standings = {overtime = {regulationRounds = 12}}
			local includesGames = queriesGames{tabletype = 'swiss', round1 = {matches = 'M1'}, overtime = 'true'}
			Info.config.standings = originalStandingsConfig
			assert.is_true(includesGames)
		end)
	end)

	it('errors on an unknown table type', function()
		assert.error(function()
			StandingsTable.fromTemplate{tabletype = 'league'}
		end)
	end)

	describe('tiebreaker reset', function()
		local StandingsParser = require('Module:Standings/Parser')

		before_each(function()
			spy.on(StandingsParser, 'parse')
		end)

		after_each(function()
			---@diagnostic disable-next-line: undefined-field
			StandingsParser.parse:revert()
		end)

		---@param tiebreakerReset string?
		---@return boolean?
		local function parsedTiebreakerReset(tiebreakerReset)
			StandingsTable.fromTemplate{
				tabletype = 'group',
				import = 'false',
				tiebreakerreset = tiebreakerReset,
				round1 = {started = 'true', finished = 'true'},
				{type = 'literal', name = 'Alpha', r1 = '3'},
			}
			---@diagnostic disable-next-line: undefined-field
			return StandingsParser.parse.calls[1].vals[8].tiebreakerReset
		end

		it('passes the tiebreakerreset input to the parser', function()
			assert.is_true(parsedTiebreakerReset('true'))
		end)

		it('does not reset when tiebreakerreset is disabled', function()
			assert.is_false(parsedTiebreakerReset('false'))
		end)

		it('does not reset by default', function()
			assert.is_false(parsedTiebreakerReset(nil))
		end)
	end)
end)
