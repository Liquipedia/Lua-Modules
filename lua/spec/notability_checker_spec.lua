--- Triple Comment to Enable our LLS Plugin
insulate('NotabilityChecker', function()
	local DateExt, NotabilityChecker, Table
	local YEAR = 365.2425 * 86400

	---@param yearsAgo number
	---@return string
	local function dateYearsAgo(yearsAgo)
		return os.date('!%Y-%m-%d', DateExt.getCurrentTimestamp() - math.floor(yearsAgo * YEAR)) --[[@as string]]
	end

	---@param props table
	---@return placement
	local function placement(props)
		return Table.merge({
			liquipediatier = '1',
			liquipediatiertype = '',
			placement = '1',
			date = dateYearsAgo(0.1),
			extradata = {},
			mode = '',
		}, props)
	end

	setup(function()
		SetActiveWiki('rocketleague')
		Table = require('Module:Table')
		DateExt = require('Module:Date/Ext')
		NotabilityChecker = require('Module:NotabilityChecker')
	end)

	teardown(function()
		SetActiveWiki()
	end)

	describe('points that drop off by placement', function()
		it('divides by placement', function()
			assert.are_equal(1000, NotabilityChecker.calculatePlacementWeight(placement{}))
			assert.are_equal(500, NotabilityChecker.calculatePlacementWeight(placement{placement = '2'}))
			assert.are_equal(250, NotabilityChecker.calculatePlacementWeight(placement{placement = '2-3', liquipediatier = '2'}))
		end)

		it('uses the tier type exponent', function()
			assert.are_equal(250 / 9, NotabilityChecker.calculatePlacementWeight(
				placement{placement = '3', liquipediatiertype = 'Qualifier'}
			))
		end)

		it('normalizes tier type names', function()
			assert.are_equal(250, NotabilityChecker.calculatePlacementWeight(
				placement{liquipediatiertype = 'Show Match'}
			))
		end)
	end)

	describe('modifiers', function()
		it('applies mode multipliers', function()
			assert.are_equal(500, NotabilityChecker.calculatePlacementWeight(placement{mode = '2v2'}))
			assert.are_equal(250, NotabilityChecker.calculatePlacementWeight(placement{mode = '1v1'}))
		end)

		it('applies the notability mod', function()
			assert.are_equal(2000, NotabilityChecker.calculatePlacementWeight(placement{extradata = {notabilitymod = '2'}}))
			assert.are_equal(0, NotabilityChecker.calculatePlacementWeight(placement{extradata = {notabilitymod = '0'}}))
		end)

		it('applies date loss unless ignored', function()
			assert.are_equal(1000, NotabilityChecker.calculatePlacementWeight(placement{date = dateYearsAgo(3.5)}))
			assert.are_equal(500 / 4, NotabilityChecker.calculatePlacementWeight(
				placement{liquipediatier = '2', date = dateYearsAgo(3.5)}
			))
			assert.are_equal(500, NotabilityChecker.calculatePlacementWeight(
				placement{liquipediatier = '2', date = dateYearsAgo(-1)}
			))
		end)
	end)

	describe('placements', function()
		it('treats forfeits as first and second', function()
			assert.are_equal(1000, NotabilityChecker.calculatePlacementWeight(placement{placement = 'W'}))
			assert.are_equal(500, NotabilityChecker.calculatePlacementWeight(placement{placement = 'l'}))
		end)

		it('scores unknown tiers and placements as zero', function()
			assert.are_equal(0, NotabilityChecker.calculatePlacementWeight(placement{placement = ''}))
			assert.are_equal(0, NotabilityChecker.calculatePlacementWeight(placement{placement = 'dq'}))
			assert.are_equal(0, NotabilityChecker.calculatePlacementWeight(placement{liquipediatier = '-1'}))
			assert.are_equal(0, NotabilityChecker.calculatePlacementWeight(placement{liquipediatiertype = 'Unknown'}))
		end)
	end)

	describe('run', function()
		it('sums team weight and average person weight', function()
			local LpdbStub = stub(mw.ext.LiquipediaDB, 'lpdb', function(_, parameters)
				if (parameters.offset or 0) > 0 then
					return {}
				end
				if parameters.conditions:find('Team A', 1, true) then
					return {placement{opponentname = 'Team A', pagename = 'A', tournament = 'A'}}
				elseif parameters.conditions:find('Player B', 1, true) then
					return {placement{opponentname = 'Player B', placement = '2', pagename = 'B', tournament = 'B'}}
				end
				return {}
			end)

			local output = tostring(NotabilityChecker.run{team = 'Team A', player1 = 'Player B', player2 = 'Player C'})

			assert.is_truthy(output:find('<b>Final weight:</b> 1250', 1, true))
			assert.is_truthy(output:find('team is <b>NOTABLE</b>', 1, true))
			assert.is_truthy(output:find('Tournaments found featuring Player C', 1, true))

			LpdbStub:revert()
		end)
	end)
end)

insulate('NotabilityChecker placement ranges', function()
	local NotabilityChecker, Table

	setup(function()
		SetActiveWiki('deltaforce')
		Table = require('Module:Table')
		NotabilityChecker = require('Module:NotabilityChecker')
	end)

	teardown(function()
		SetActiveWiki()
	end)

	---@param props table
	---@return number
	local function weight(props)
		return NotabilityChecker.calculatePlacementWeight(Table.merge({
			liquipediatier = '1',
			liquipediatiertype = '',
			date = '2000-01-01',
			extradata = {},
			mode = '',
		}, props))
	end

	it('awards points per placement range', function()
		assert.are_equal(20, weight{placement = '6'})
		assert.are_equal(15, weight{placement = '7-8'})
		assert.are_equal(10, weight{placement = '200'})
		assert.are_equal(0, weight{placement = '13', liquipediatier = '3'})
	end)

	it('uses mode specific tiers', function()
		assert.are_equal(10, weight{placement = '6', mode = 'Warfare'})
		assert.are_equal(5, weight{placement = '9', mode = 'wf'})
		assert.are_equal(15, weight{placement = '9', mode = 'ops'})
	end)
end)
