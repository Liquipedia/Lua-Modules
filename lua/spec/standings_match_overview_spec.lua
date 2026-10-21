--- Triple Comment to Enable our LLS Plugin
describe('Standings match overview widget', function()
	local MatchOverview = require('Module:Widget/Standings/MatchOverview')

	---Alpha (the row's opponent) against Bravo (the shown opponent)
	---@param props {phase: string?, winner: integer?, placements: integer[]?, statuses: string[]?, scores: integer[]?}
	---@return string
	local function render(props)
		local placements = props.placements or {}
		local statuses = props.statuses or {}
		local scores = props.scores or {}
		local opponents = {}
		for index, name in ipairs({'Alpha', 'Bravo'}) do
			table.insert(opponents, {
				type = 'literal',
				name = name,
				placement = placements[index],
				status = statuses[index] or 'S',
				score = scores[index],
			})
		end
		return tostring(MatchOverview{
			match = {phase = props.phase or 'finished', winner = props.winner, opponents = opponents},
			opponentIndex = 1,
		})
	end

	---@param html string
	---@return string?
	local function resultType(html)
		return html:match('result%-(%a+)')
	end

	---@param html string
	---@return integer
	local function boldCount(html)
		local _, count = html:gsub('font%-weight:bold', '')
		return count
	end

	it('shows a win of the row opponent', function()
		local html = render{winner = 1, placements = {1, 2}, scores = {2, 0}}
		assert.are_equal('win', resultType(html))
		assert.are_equal(1, boldCount(html))
	end)

	it('shows a loss of the row opponent', function()
		local html = render{winner = 2, placements = {2, 1}, scores = {0, 2}}
		assert.are_equal('loss', resultType(html))
		assert.are_equal(1, boldCount(html))
	end)

	it('shows a draw', function()
		local html = render{winner = 0, placements = {1, 1}, scores = {1, 1}}
		assert.are_equal('draw', resultType(html))
		assert.are_equal(0, boldCount(html))
	end)

	it('shows a double loss as a loss without a bold winner', function()
		local html = render{winner = -1, placements = {2, 2}, statuses = {'L', 'L'}}
		assert.are_equal('loss', resultType(html))
		assert.are_equal(0, boldCount(html))
	end)

	it('shows unfinished matches without a result', function()
		local html = render{phase = 'ongoing', scores = {1, 0}}
		assert.are_equal('default', resultType(html))
	end)
end)
