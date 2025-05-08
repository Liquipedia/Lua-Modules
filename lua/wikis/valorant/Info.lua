---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2020,
	wikiName = 'valorant',
	name = 'VALORANT',
	defaultGame = 'val',
	games = {
		val = {
			abbreviation = 'VAL',
			name = 'VALORANT',
			link = 'VALORANT',
			logo = {
				darkMode = 'VALORANT allmode.png',
				lightMode = 'VALORANT allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'VALORANT allmode.png',
				lightMode = 'VALORANT allmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = true,
			allowManual = true,
		},
		match2 = {
			status = 2,
			matchWidth = 180,
			gameScoresIfBo1 = true,
		},
		transfers = {
			contractDatabase = {
				-- luacheck: push ignore
				link = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRmmWiBmMMD43m5VtZq54nKlmj0ZtythsA1qCpegwx-iRptx2HEsG0T3cQlG1r2AIiKxBWnaurJZQ9Q/pubhtml',
				-- luacheck: pop
				display = 'VALORANT Champions Tour Global Contract Database'
			},
		},
		infoboxPlayer = {
			autoTeam = true,
			automatedHistory = {
				mode = 'automatic',
			},
		},
	},
}
