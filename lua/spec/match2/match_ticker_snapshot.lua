--- Triple Comment to Enable our LLS Plugin

insulate('Match Ticker Card', function()
	local Array = require('Module:Array')
	local MatchGroupUtil = require('Module:MatchGroup/Util/Custom')

	local Html = require('Module:Widget/Html')

	local LpdbQueryStub, MakeTitleStub, TeamTemplateMock
	local MatchTickerController, MatchTickerWrapper

	before_each(function ()
		LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
		MakeTitleStub = stub(mw.title, 'makeTitle', function(_, title, fragment)
			return {fullText = title .. (fragment and ('#' .. fragment) or '')}
		end)
		MatchTickerController = require('Module:MatchTicker/Controller')
		MatchTickerWrapper = require('Module:Widget/Match/Ticker/Wrapper')
		TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		TeamTemplateMock.setUp()
	end)

	after_each(function ()
		TeamTemplateMock.tearDown()
		MakeTitleStub:revert()
		LpdbQueryStub:revert()
	end)

	---@param finished boolean
	---@return {match: MatchGroupUtilMatch, gameData: MatchTickerGameData?}[]
	local function buildTickerMatches(finished)
		local records = Array.filter(Array.sub(require('test_assets.lpdb_match2'), 1, 3), function (record)
			return (record.finished == '1') == finished
		end)
		-- Split matches whose games are played on different dates into one card per game, as the ticker does
		return Array.flatMap(records, function (record)
			---@diagnostic disable-next-line: invisible, missing-fields
			return MatchTickerController.expandGamesOfMatch(MatchGroupUtil.matchFromRecord(record), {
				upcoming = not finished,
				recent = finished,
			})
		end)
	end

	it('upcoming snapshot', function()
		GoldenTest('match_ticker_entity_page_upcoming', tostring(MatchTickerWrapper{
			matches = buildTickerMatches(false),
			variant = 'horizontal',
		}))
	end)

	it('completed snapshot', function()
		-- Completed matches are listed in the recent tab of the main page ticker
		GoldenTest('match_ticker_ffa_completed', tostring(Html.Div{
			classes = {'match-ticker-filterable-container'},
			attributes = {['data-match-ticker-type'] = 'recent'},
			children = MatchTickerWrapper{
				matches = buildTickerMatches(true),
				variant = 'carousel',
			},
		}))
	end)
end)
