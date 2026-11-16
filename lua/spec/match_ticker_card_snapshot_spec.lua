--- Triple Comment to Enable our LLS Plugin

insulate('Match Ticker Card', function()
	local Array = require('Module:Array')
	local MatchGroupUtil = require('Module:MatchGroup/Util/Custom')

	local Html = require('Module:Widget/Html')
	local Switch = require('Module:Widget/Switch')

	it('snapshot', function()
		local LoadJsonDataStub = stub(mw, 'loadJsonData', {})
		local LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
		local MakeTitleStub = stub(mw.title, 'makeTitle', function(_, title, fragment)
			return {fullText = title .. (fragment and ('#' .. fragment) or '')}
		end)
		local MatchTickerCard = require('Module:Widget/Match/Ticker/Card')
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		TeamTemplateMock.setUp()

		local MatchRecords = require('test_assets.match_ticker_cards')

		local cards = Array.map(MatchRecords, function(record)
			return Html.Div{
				css = {width = '15.625rem'},
				children = MatchTickerCard{match = MatchGroupUtil.matchFromRecord(record)}
			}
		end)

		GoldenTest('match_ticker_card', tostring(Switch{
			label = 'Show Countdown',
			switchGroup = 'countdown',
			storeValue = true,
			defaultActive = true,
			css = {margin = '1rem 0', ['justify-content'] = 'center'},
			content = Html.Div{
				css = {
					display = 'flex',
					['flex-wrap'] = 'wrap',
				},
				children = cards,
			}
		}))

		TeamTemplateMock.tearDown()
		MakeTitleStub:revert()
		LpdbQueryStub:revert()
		LoadJsonDataStub:revert()
	end)
end)
