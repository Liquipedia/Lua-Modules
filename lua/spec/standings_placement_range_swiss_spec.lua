--- Triple Comment to Enable our LLS Plugin
describe('Standings Swiss Placement Range', function()
	local Array = require('Module:Array')
	local StandingsPlacementRange = require('Module:Standings/PlacementRange')
	local StandingsSwissPlacementRange = require('Module:Standings/PlacementRange/Swiss')

	local GSL = {type = 'swiss', winsToAdvance = 2, lossesToEliminate = 2}
	local SWISS = {type = 'swiss', winsToAdvance = 3, lossesToEliminate = 3}

	---@param count integer
	---@return table[]
	local function opponentsData(count)
		return Array.map(Array.range(1, count), function() return {} end)
	end

	---@param records {[1]: integer, [2]: integer, [3]: integer?}[] wins, losses and number of opponents
	---@return table[]
	local function makeOpponents(records)
		return Array.flatMap(records, function(record)
			return Array.map(Array.range(1, record[3] or 1), function()
				return {match = {w = record[1], d = 0, l = record[2]}, extradata = {}}
			end)
		end)
	end

	---@param records {[1]: integer, [2]: integer, [3]: integer?}[]
	---@return {w: integer, d: integer, l: integer}[]
	local function recordsOf(records)
		return Array.map(makeOpponents(records), function(opponent) return opponent.match end)
	end

	---Gives the opponents the slots of a table ranked by the record
	---@param opponents table[]
	local function assignSlots(opponents)
		local order = Array.range(1, #opponents)
		table.sort(order, function(a, b)
			local recordA, recordB = opponents[a].match, opponents[b].match
			if recordA.w ~= recordB.w then
				return recordA.w > recordB.w
			elseif recordA.l ~= recordB.l then
				return recordA.l < recordB.l
			end
			return a < b
		end)
		Array.forEach(order, function(opponentIndex, slot)
			opponents[opponentIndex].slotindex = slot
		end)
	end

	---@param opponents table[]
	---@param format StandingsSwissFormat
	local function computeRanges(opponents, format)
		if not opponents[1].slotindex then
			assignSlots(opponents)
		end
		local calculator = StandingsPlacementRange.calculator(format, opponentsData(#opponents))
		if calculator then
			StandingsPlacementRange.setRanges(calculator, opponents, 1)
		end
	end

	---@param opponents table[]
	---@return table<string, {[1]: integer, [2]: integer}>
	local function rangesByRecord(opponents)
		local ranges = {}
		Array.forEach(opponents, function(opponent)
			ranges[opponent.match.w .. '-' .. opponent.match.l] = opponent.placerange
		end)
		return ranges
	end

	describe('count final records', function()
		it('follows the fixed distribution of a 16 opponent swiss', function()
			assert.are_same(
				{[3] = {[0] = 2, [1] = 3, [2] = 3}, [2] = {[3] = 3}, [1] = {[3] = 3}, [0] = {[3] = 2}},
				StandingsSwissPlacementRange.countFinalRecords(recordsOf{{0, 0, 16}}, SWISS)
			)
		end)

		it('has one opponent per record in a gsl group', function()
			assert.are_same(
				{[2] = {[0] = 1, [1] = 1}, [1] = {[2] = 1}, [0] = {[2] = 1}},
				StandingsSwissPlacementRange.countFinalRecords(recordsOf{{0, 0, 4}}, GSL)
			)
		end)

		it('is the same in the middle of a round', function()
			local midRound = recordsOf{{2, 0, 2}, {1, 1, 2}, {1, 0, 4}, {1, 1, 4}, {0, 2, 4}}
			assert.are_same(
				StandingsSwissPlacementRange.countFinalRecords(recordsOf{{0, 0, 16}}, SWISS),
				StandingsSwissPlacementRange.countFinalRecords(midRound, SWISS)
			)
		end)

		it('is nil for a group with an odd number of opponents', function()
			assert.is_nil(StandingsSwissPlacementRange.countFinalRecords({{w = 0, l = 0}, {w = 0, l = 0}, {w = 0, l = 0}}, GSL))
		end)

		it('is nil for records outside the format', function()
			assert.is_nil(StandingsSwissPlacementRange.countFinalRecords({{w = 3, l = 0}, {w = 0, l = 1}}, GSL))
			assert.is_nil(StandingsSwissPlacementRange.countFinalRecords({{w = 2, l = 2}, {w = 0, l = 1}}, GSL))
		end)
	end)

	describe('gsl', function()
		it('has the expected range for every record', function()
			local cases = {
				{{0, 0, 4}},
				{{1, 0, 2}, {0, 1, 2}},
				{{2, 0}, {1, 1, 2}, {0, 2}},
				{{2, 0}, {2, 1}, {1, 2}, {0, 2}},
			}
			local ranges = {}
			Array.forEach(cases, function(records)
				local opponents = makeOpponents(records)
				computeRanges(opponents, GSL)
				for record, range in pairs(rangesByRecord(opponents)) do
					ranges[record] = range
				end
			end)
			assert.are_same({
				['0-0'] = {1, 4},
				['1-0'] = {1, 3},
				['0-1'] = {2, 4},
				['1-1'] = {2, 3},
				['2-0'] = {1, 1},
				['2-1'] = {2, 2},
				['1-2'] = {3, 3},
				['0-2'] = {4, 4},
			}, ranges)
		end)

		it('contains the final placement after every match of every possible group', function()
			for outcome = 0, 31 do
				local records = recordsOf{{0, 0, 4}}
				local snapshots = {}
				local resultIndex = 0
				local function play(first, second)
					resultIndex = resultIndex + 1
					local firstWins = math.floor(outcome / 2 ^ (resultIndex - 1)) % 2 == 0
					local winner, loser = first, second
					if not firstWins then
						winner, loser = second, first
					end
					records[winner].w = records[winner].w + 1
					records[loser].l = records[loser].l + 1
					table.insert(snapshots, Array.map(records, function(record) return {w = record.w, d = 0, l = record.l} end))
					return winner, loser
				end

				local winner1, loser1 = play(1, 2)
				local winner2, loser2 = play(3, 4)
				local _, winnersMatchLoser = play(winner1, winner2)
				local eliminationMatchWinner = play(loser1, loser2)
				play(winnersMatchLoser, eliminationMatchWinner)

				local final = Array.map(records, function(record) return {match = record, extradata = {}} end)
				computeRanges(final, GSL)
				Array.forEach(snapshots, function(snapshot)
					local opponents = Array.map(snapshot, function(record) return {match = record, extradata = {}} end)
					computeRanges(opponents, GSL)
					Array.forEach(opponents, function(opponent, index)
						local placement = final[index].placerange[1]
						assert.is_true(opponent.placerange[1] <= placement and placement <= opponent.placerange[2])
					end)
				end)
			end
		end)
	end)

	describe('ranges by record', function()
		it('ranks the final records by wins and then by fewer losses', function()
			local ranges = StandingsSwissPlacementRange.new(SWISS, opponentsData(16)).rangesByRecord
			assert.are_same({1, 2}, ranges[3][0])
			assert.are_same({3, 5}, ranges[3][1])
			assert.are_same({6, 8}, ranges[3][2])
			assert.are_same({9, 11}, ranges[2][3])
			assert.are_same({12, 14}, ranges[1][3])
			assert.are_same({15, 16}, ranges[0][3])
			assert.are_same({1, 16}, ranges[0][0])
		end)

		it('is nil for a number of opponents that does not fit the format', function()
			assert.is_nil(StandingsSwissPlacementRange.new(GSL, opponentsData(0)))
			assert.is_nil(StandingsSwissPlacementRange.new(GSL, opponentsData(3)))
			assert.is_nil(StandingsSwissPlacementRange.new(SWISS, opponentsData(8)))
		end)
	end)

	describe('16 opponent swiss', function()
		it('has the expected ranges after two rounds', function()
			local opponents = makeOpponents{{2, 0, 4}, {1, 1, 8}, {0, 2, 4}}
			computeRanges(opponents, SWISS)
			assert.are_same({['2-0'] = {1, 11}, ['1-1'] = {3, 14}, ['0-2'] = {6, 16}}, rangesByRecord(opponents))
		end)

		it('has the expected ranges after four rounds', function()
			local opponents = makeOpponents{{3, 0, 2}, {3, 1, 3}, {2, 2, 6}, {1, 3, 3}, {0, 3, 2}}
			computeRanges(opponents, SWISS)
			assert.are_same({
				['3-0'] = {1, 2},
				['3-1'] = {3, 5},
				['2-2'] = {6, 11},
				['1-3'] = {12, 14},
				['0-3'] = {15, 16},
			}, rangesByRecord(opponents))
		end)
	end)

	describe('random 16 opponent swiss', function()
		-- Seeded generator, the same on every Lua version
		local seed = 12345
		local function random(max)
			seed = (seed * 1103515245 + 12345) % 2147483648
			return seed % max + 1
		end

		---@param opponents table[]
		---@return table[]
		local function snapshot(opponents)
			return Array.map(opponents, function(opponent)
				return {match = {w = opponent.match.w, d = 0, l = opponent.match.l}, extradata = {}}
			end)
		end

		it('contains the final placements after every match', function()
			for _ = 1, 50 do
				local opponents = makeOpponents{{0, 0, 16}}
				local snapshots = {}
				while true do
					local pools = {}
					for index, opponent in ipairs(opponents) do
						if opponent.match.w < SWISS.winsToAdvance and opponent.match.l < SWISS.lossesToEliminate then
							local key = opponent.match.w .. '-' .. opponent.match.l
							pools[key] = pools[key] or {}
							table.insert(pools[key], index)
						end
					end
					if next(pools) == nil then
						break
					end
					local keys = Array.extractKeys(pools)
					table.sort(keys)
					for _, key in ipairs(keys) do
						local pool = pools[key]
						while #pool > 0 do
							local first = table.remove(pool, random(#pool))
							local second = table.remove(pool, random(#pool))
							local winner, loser = first, second
							if random(2) == 1 then
								winner, loser = second, first
							end
							opponents[winner].match.w = opponents[winner].match.w + 1
							opponents[loser].match.l = opponents[loser].match.l + 1
							table.insert(snapshots, snapshot(opponents))
						end
					end
				end

				local final = snapshot(opponents)
				computeRanges(final, SWISS)
				Array.forEach(snapshots, function(opponentsAfterMatch)
					computeRanges(opponentsAfterMatch, SWISS)
					Array.forEach(opponentsAfterMatch, function(opponent, index)
						local finalRange = final[index].placerange
						assert.is_true(opponent.placerange[1] <= finalRange[1] and finalRange[2] <= opponent.placerange[2])
					end)
				end)
			end
		end)
	end)

	describe('is not set', function()
		local function assertNoRanges(opponents)
			computeRanges(opponents, GSL)
			Array.forEach(opponents, function(opponent)
				assert.is_nil(opponent.placerange)
			end)
		end

		it('with draws', function()
			local opponents = makeOpponents{{1, 0, 2}, {0, 1, 2}}
			opponents[1].match.d = 1
			assertNoRanges(opponents)
		end)

		it('with a disqualified opponent', function()
			local opponents = makeOpponents{{1, 0, 2}, {0, 1, 2}}
			opponents[1].extradata.disqualified = true
			assertNoRanges(opponents)
		end)

		it('in tables with overtime', function()
			local opponents = makeOpponents{{1, 0, 2}, {0, 1, 2}}
			opponents[1].overtime = {w = 0, l = 0}
			assertNoRanges(opponents)
		end)

		it('with records that same record pairings can not lead to', function()
			assertNoRanges(makeOpponents{{2, 0, 2}, {0, 2, 2}})
		end)

		it('from the round a match record is adjusted', function()
			local data = opponentsData(4)
			data[1].adjustments = {[2] = {match = {w = 1}}}
			local calculator = StandingsSwissPlacementRange.new(GSL, data)
			---@cast calculator -nil
			local opponents = makeOpponents{{1, 0, 2}, {0, 1, 2}}
			assert.is_not_nil(calculator:rangesFor(opponents, 1))
			assert.is_nil(calculator:rangesFor(opponents, 2))
		end)
	end)
end)
