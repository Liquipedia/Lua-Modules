--- Triple Comment to Enable our LLS Plugin

insulate('Match Ticker Card', function()
	it('snapshot', function()
		local LoadJsonDataStub = stub(mw, 'loadJsonData', {})
		local LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
		local MakeTitleStub = stub(mw.title, 'makeTitle', function(_, title, fragment)
			return {fullText = title .. (fragment and ('#' .. fragment) or '')}
		end)
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		TeamTemplateMock.setUp()

		local Array = require('Module:Array')
		local Html = require('Module:Widget/Html')
		local MatchGroupUtil = require('Module:MatchGroup/Util/Custom')
		local MatchTickerCard = require('Module:Widget/Match/Ticker/Card')
		local MatchRecords = require('test_assets.match_ticker_cards')

		local cards = Array.map(MatchRecords, function(record)
			return MatchTickerCard{match = MatchGroupUtil.matchFromRecord(record)}
		end)

		GoldenTest('match_ticker_card', tostring(Html.Div{
			css = {display = 'flex', gap = '0.5rem', ['align-items'] = 'flex-start'},
			children = cards,
		}))

		TeamTemplateMock.tearDown()
		MakeTitleStub:revert()
		LpdbQueryStub:revert()
		LoadJsonDataStub:revert()
	end)
end)
