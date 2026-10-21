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

	it('errors on an unknown table type', function()
		assert.error(function()
			StandingsTable.fromTemplate{tabletype = 'league'}
		end)
	end)
end)
