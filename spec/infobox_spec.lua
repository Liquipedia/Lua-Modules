--- Triple Comment to Enable our LLS Plugin
insulate('Infobox', function()
	insulate('League', function ()
		allwikis('smoke', function (args, wikiName)
			local LpdbSquadStub = stub(mw.ext.LiquipediaDB, 'lpdb_tournament')
			local LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
			local InfoboxLeagueCustom = require('Module:Infobox/League/Custom')

			GoldenTest('infobox_league_' .. wikiName, tostring(InfoboxLeagueCustom.run(args.input)))

			LpdbSquadStub:revert()
			LpdbQueryStub:revert()
		end, {default = {
			input = {
				require('test_assets.tournaments').dummy
			},
		}})
	end)
end)
