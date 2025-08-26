--- Triple Comment to Enable our LLS Plugin
insulate('Standings', function()
	insulate('FFA', function ()
		allwikis('smoke', function (args, wikiName)
			local LpdbStandingsTableStub = stub(mw.ext.LiquipediaDB, 'lpdb_standingstable')
			local LpdbStandingsEntryStub = stub(mw.ext.LiquipediaDB, 'lpdb_standingsentry')
			local LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
			local StandingsTable = require('Module:Standings/Table')

			GoldenTest('standings_ffa_' .. wikiName, tostring(StandingsTable.fromTemplate(args.input)))

			LpdbStandingsTableStub:revert()
			LpdbStandingsEntryStub:revert()
			LpdbQueryStub:revert()
		end, {default = {
			input = {
				{
					"heavy",
					r1 = 139,
					r2 = 83,
					r3 = 83,
					r4 = 85,
					r5 = 95,
					r6 = 81,
					type = "solo"
				},
				{
					"flash",
					r1 = 61,
					r2 = 120,
					r3 = 172,
					r4 = 61,
					r5 = 73,
					r6 = 63,
					type = "solo"
				},
				{
					"vgaming",
					r1 = 87,
					r2 = 79,
					r3 = 131,
					r4 = 97,
					r5 = 79,
					r6 = 69,
					type = "solo"
				},
				{
					"box",
					r1 = 12,
					r2 = 67,
					r3 = 74,
					r4 = 99,
					r5 = 93,
					r6 = 145,
					type = "solo"
				},
				{
					"proa",
					r1 = 63,
					r2 = 58,
					r3 = 139,
					r4 = 65,
					r5 = 21,
					r6 = 75,
					type = "solo"
				},
				{
					"eros gaming",
					r1 = 74,
					r2 = 60,
					r3 = 34,
					r4 = 80,
					r5 = 61,
					r6 = 104,
					type = "solo"
				},
				{
					"hq",
					r1 = 90,
					r2 = 73,
					r3 = 70,
					r4 = 41,
					r5 = 64,
					r6 = 39,
					type = "solo"
				},
				{
					"gao",
					r1 = 117,
					r2 = 64,
					r3 = 36,
					r4 = 44,
					r5 = 65,
					r6 = 40,
					type = "solo"
				},
				{
					"pq",
					r1 = 83,
					r2 = 94,
					r3 = 33,
					r4 = 51,
					r5 = 39,
					r6 = 56,
					type = "solo"
				},
				{
					"quality",
					r1 = 47,
					r2 = 39,
					r3 = 56,
					r4 = 61,
					r5 = 105,
					r6 = 35,
					type = "solo"
				},
				{
					"btg",
					r1 = 77,
					r2 = 62,
					r3 = 38,
					r4 = 65,
					r5 = 27,
					r6 = 70,
					type = "solo"
				},
				{
					"wasabi",
					r1 = 34,
					r2 = 52,
					r3 = 31,
					r4 = 79,
					r5 = 102,
					r6 = 38,
					type = "solo"
				},
				{
					"xgo",
					r1 = 24,
					r2 = 57,
					r3 = 17,
					r4 = 61,
					r5 = 68,
					r6 = 73,
					type = "team"
				},
				{
					"menu",
					r1 = 55,
					r2 = 47,
					r3 = 29,
					r4 = 46,
					r5 = 40,
					r6 = 79,
					type = "solo"
				},
				{
					"wp",
					r1 = 67,
					r2 = 14,
					r3 = 34,
					r4 = 40,
					r5 = 60,
					r6 = 36,
					type = "solo"
				},
				{
					"hn",
					r1 = 24,
					r2 = 36,
					r3 = 48,
					r4 = 55,
					r5 = 48,
					r6 = 24,
					type = "solo"
				},
				{
					"kfs",
					r1 = 34,
					r2 = 19,
					r3 = 60,
					r4 = 33,
					r5 = 34,
					r6 = 35,
					type = "solo"
				},
				{
					"8x",
					r1 = 16,
					r2 = 29,
					r3 = 34,
					r4 = 21,
					r5 = 18,
					r6 = 26,
					type = "solo"
				},
				bg = "1-12=up,13-18=staydown",
				round1 = {
					finished = true,
					started = true,
					title = "Week 1"
				},
				round2 = {
					finished = true,
					started = true,
					title = "Week 2"
				},
				round3 = {
					finished = true,
					started = true,
					title = "Week 3"
				},
				round4 = {
					finished = true,
					started = true,
					title = "Week 4"
				},
				round5 = {
					finished = true,
					started = true,
					title = "Week 5"
				},
				round6 = {
					finished = true,
					started = true,
					title = "Week 6"
				},
				rounds = 6,
				tabletype = 'ffa',
				title = "Group Stage Standings",
			}
		}})
	end)
end)
