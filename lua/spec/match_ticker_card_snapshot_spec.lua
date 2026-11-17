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
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		TeamTemplateMock.setUp()

		local MatchRecords = require('test_assets.match_ticker_cards')

		local cards = Array.map(MatchRecords, function(record)
			return MatchTickerCard{match = MatchGroupUtil.matchFromRecord(record)}
		end)

		GoldenTest('match_ticker_card', tostring(HorizontalContainer{
			children = cards,
		}))

		TeamTemplateMock.tearDown()
		MakeTitleStub:revert()
		LpdbQueryStub:revert()
	end)
end)
