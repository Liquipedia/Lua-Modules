--- Triple Comment to Enable our LLS Plugin
insulate('Rankings', function()
	it('dota2', function()
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		local TestAsset = require('test_assets/dota2_rankings_example')
		TeamTemplateMock.setUp()
		local LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
		local Dota2Extension = stub(mw.ext.Dota2Ranking, 'get', function() return TestAsset end)

		local RatingWidget = require('Module:Widget/Ratings')

		GoldenTest('dota2 rankings', tostring(RatingWidget{
			storageType = 'extension',
			teamLimit = 20,
		}))

		Dota2Extension:revert()
		LpdbQuery:revert()
		TeamTemplateMock.tearDown()
	end)
end)
