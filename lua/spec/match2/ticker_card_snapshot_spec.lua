--- Triple Comment to Enable our LLS Plugin

insulate('Match Ticker Card', function()
	local Array = require('Module:Array')
	local MatchGroupUtil = require('Module:MatchGroup/Util/Custom')

	local HorizontalContainer = require('Module:Widget/Match/Ticker/HorizontalContainer')

	it('snapshot', function()
		local LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
		local MakeTitleStub = stub(mw.title, 'makeTitle', function(_, title, fragment)
			return {fullText = title .. (fragment and ('#' .. fragment) or '')}
		end)
		local MatchTickerCard = require('Module:Widget/Match/Ticker/Card')
		local MatchTickerController = require('Module:MatchTicker/Controller')
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		TeamTemplateMock.setUp()

		local MatchRecords = require('test_assets.lpdb_match2')

		-- Split matches whose games are played on different dates into one card per game, as the ticker does
		local cards = Array.flatMap(MatchRecords, function(record)
			local match = MatchGroupUtil.matchFromRecord(record)
			---@diagnostic disable-next-line: invisible, missing-fields
			local expandedMatches = MatchTickerController.expandGamesOfMatch(match, {
				upcoming = not match.finished,
				recent = match.finished,
			})
			return Array.map(expandedMatches, function(expandedMatch)
				return MatchTickerCard{match = expandedMatch.match, gameData = expandedMatch.gameData}
			end)
		end)

		GoldenTest('match_ticker_card', tostring(HorizontalContainer{
			children = cards,
		}))

		TeamTemplateMock.tearDown()
		MakeTitleStub:revert()
		LpdbQueryStub:revert()
	end)
end)
