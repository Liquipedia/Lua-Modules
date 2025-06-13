---
-- @Liquipedia
-- page=Module:TestAssets/TeamTemplate/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local aliases = {
	mousesports = 'mouz',
	tl = 'team liquid',
}

local data = {
	-- historical ones
	mouz = {
		['0000-01-01'] = 'mousesports orig',
		['2016-06-01'] = 'mousesports 2016',
		['2021-10-14'] = 'mouz 2021',
	},
	['team liquid'] = {
		['0000-01-01'] = 'team liquid orig',
		['2017-01-17'] = 'team liquid 2017',
		['2019-09-17'] = 'team liquid 2019',
		['2020-02-04'] = 'team liquid 2020',
		['2023-02-21'] = 'team liquid 2023',
		['2024-02-20'] = 'team liquid 2024',
	},
	-- mouz subtemplates
	['mousesports orig'] = {
		bracketname = "mousesports",
		image = "Mousesports new.png",
		imagedark = "Mousesports new.png",
		legacyimage = "",
		legacyimagedark = "",
		name = "mousesports",
		page = "mousesports",
		shortname = "mouz",
		templatename = "mousesports orig",
	},
	['mousesports 2016'] = {
		bracketname = "mousesports",
		image = "Mousesports 2016 allmodes.png",
		imagedark = "Mousesports 2016 allmodes.png",
		legacyimage = "",
		legacyimagedark = "",
		name = "mousesports",
		page = "mousesports",
		shortname = "mouz",
		templatename = "mousesports 2016",
	},
	['mouz 2021'] = {
		bracketname = "MOUZ",
		image = "MOUZ allmode.png",
		imagedark = "MOUZ allmode.png",
		legacyimage = "",
		legacyimagedark = "",
		name = "MOUZ",
		page = "MOUZ",
		shortname = "MOUZ",
		templatename = "mouz 2021",
	},
	-- tl subtemplates
	['team liquid orig'] = {
		bracketname = "Team Liquid",
		image = "Team Liquid lightmode.png",
		imagedark = "Team Liquid lightmode.png",
		legacyimage = "",
		legacyimagedark = "",
		name = "Team Liquid",
		page = "Team Liquid",
		shortname = "Liquid",
		templatename = "team liquid orig",
	},
	['team liquid 2017'] = {
		bracketname = "Team Liquid",
		image = "Team Liquid 2017 lightmode.png",
		imagedark = "Team Liquid 2017 darkmode.png",
		legacyimage = "",
		legacyimagedark = "",
		name = "Team Liquid",
		page = "Team Liquid",
		shortname = "Liquid",
		templatename = "team liquid 2017",
	},
	['team liquid 2019'] = {
		bracketname = "Team Liquid",
		image = "Team Liquid 2019 lightmode.png",
		imagedark = "Team Liquid 2019 darkmode.png",
		legacyimage = "",
		legacyimagedark = "",
		name = "Team Liquid",
		page = "Team Liquid",
		shortname = "Liquid",
		templatename = "team liquid 2019",
	},
	['team liquid 2020'] = {
		bracketname = "Team Liquid",
		image = "Team Liquid 2020 lightmode.png",
		imagedark = "Team Liquid 2020 darkmode.png",
		legacyimage = "",
		legacyimagedark = "",
		name = "Team Liquid",
		page = "Team Liquid",
		shortname = "Liquid",
		templatename = "team liquid 2020",
	},
	['team liquid 2023'] = {
		bracketname = "Team Liquid",
		image = "Team Liquid 2023 lightmode.png",
		imagedark = "Team Liquid 2023 darkmode.png",
		legacyimage = "",
		legacyimagedark = "",
		name = "Team Liquid",
		page = "Team Liquid",
		shortname = "Liquid",
		templatename = "team liquid 2023",
	},
	['team liquid 2024'] = {
		bracketname = "Team Liquid",
		image = "Team Liquid 2024 lightmode.png",
		imagedark = "Team Liquid 2024 darkmode.png",
		legacyimage = "",
		legacyimagedark = "",
		name = "Team Liquid",
		page = "Team Liquid",
		shortname = "Liquid",
		templatename = "team liquid 2024",
	},
	-- a non-historical TT
	streamerzone = {
		bracketname = "Streamerzone",
		image = "Streamerzone lightmode.png",
		imagedark = "Streamerzone darkmode.png",
		legacyimage = "",
		legacyimagedark = "",
		name = "Streamerzone",
		page = "Streamerzone",
		shortname = "SZ",
		templatename = "streamerzone",
	},
}

return {
	data = data,
	aliases = aliases,
}
