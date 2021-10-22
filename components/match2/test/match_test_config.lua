---
-- @Liquipedia
-- wiki=commons
-- page=Module:Match/testcases/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchTestConfig = {}

MatchTestConfig.EXAMPLE_MATCH = {
	['bracketdata'] = {
		['bracketindex'] = 0,
		['sectionheader'] = '',
		['title'] = 'Round 2 High Matches',
		['type'] = 'matchlist',
	},
	['bracketid'] = 'FALLOCR1R2',
	['date'] = '2021-10-15T06:45:00+00:00',
	['dateexact'] = true,
	['extradata'] = {
		['isconverted'] = 0,
		['isfeatured'] = false,
		['octane'] = '6f6a-ground-zero-gaming-vs-the-grogans',
		['team1icon'] = '',
		['team2icon'] = '',
	},
	['finished'] = 'true',
	['map1'] = {
		['extradata'] = {},
		['map'] = 'DFH Stadium',
		['mode'] = '3v3',
		['participants'] = {},
		['scores'] = {
			'3',
			'2',
		},
		['winner'] = 1,
	},
	['map2'] = {
		['extradata'] = {
			['ot'] = 'true',
			['otlength'] = '+0:10',
		},
		['map'] = 'DFH Stadium',
		['mode'] = '3v3',
		['participants'] = {},
		['scores'] = {
			'2',
			'1',
		},
		['winner'] = 1,
	},
	['map3'] = {
		['extradata'] = {},
		['map'] = 'DFH Stadium',
		['mode'] = '3v3',
		['participants'] = {},
		['scores'] = {
			'1',
			'2',
		},
		['winner'] = 2,
	},
	['map4'] = {
		['extradata'] = {
			['ot'] = 'true',
			['otlength'] = '+0:25',
		},
		['map'] = 'DFH Stadium',
		['mode'] = '3v3',
		['participants'] = {},
		['scores'] = {
			'2',
			'1',
		},
		['winner'] = 1,
	},
	['matchid'] = '0001',
	['mode'] = '3v3',
	['octane'] = '6f6a-ground-zero-gaming-vs-the-grogans',
	['opponent1'] = {
		['icon'] = 'Ground Zero Gaming 2019 std.png',
		['name'] = 'Ground Zero Gaming',
		['placement'] = 1,
		['score'] = '3',
		['status'] = 'S',
		['template'] = 'ground zero gaming 2019',
		['type'] = 'team',
	},
	['opponent2'] = {
		['icon'] = 'Rocket_League.png',
		['name'] = 'The Grogans',
		['placement'] = 2,
		['score'] = '1',
		['status'] = 'S',
		['template'] = 'the grogans',
		['type'] = 'team',
	},
	['parent'] = '',
	['stream'] = {
		['twitch'] = 'monyoce',
	},
	['twitch'] = 'monyoce',
	['winner'] = 1,
}

MatchTestConfig.EXPECTED_OUTPUT_AFTER_SPLIT = {
	['gameRecords'] = {
		{
			['extradata'] = {},
			['map'] = 'DFH Stadium',
			['mode'] = '3v3',
			['participants'] = {},
			['scores'] = {
				'3',
				'2',
			},
			['winner'] = 1,
		},
		{
			['extradata'] = {
				['ot'] = 'true',
				['otlength'] = '+0:10',
			},
			['map'] = 'DFH Stadium',
			['mode'] = '3v3',
			['participants'] = {
			},
			['scores'] = {
				'2',
				'1',
			},
			['winner'] = 1,
		},
		{
			['extradata'] = {},
			['map'] = 'DFH Stadium',
			['mode'] = '3v3',
			['participants'] = {},
			['scores'] = {
				'1',
				'2',
			},
			['winner'] = 2,
		},
		{
			['extradata'] = {
				['ot'] = 'true',
				['otlength'] = '+0:25',
			},
			['map'] = 'DFH Stadium',
			['mode'] = '3v3',
			['participants'] = {},
			['scores'] = {
				'2',
				'1',
			},
			['winner'] = 1,
		},
	},
	['matchRecord'] = {
		['bracketdata'] = {
			['bracketindex'] = 0,
			['sectionheader'] = '',
			['title'] = 'Round 2 High Matches',
			['type'] = 'matchlist',
		},
		['bracketid'] = 'FALLOCR1R2',
		['date'] = '2021-10-15T06:45:00+00:00',
		['dateexact'] = true,
		['extradata'] = {
			['isconverted'] = 0,
			['isfeatured'] = false,
			['octane'] = '6f6a-ground-zero-gaming-vs-the-grogans',
			['team1icon'] = '',
			['team2icon'] = '',
		},
		['finished'] = 'true',
		['matchid'] = '0001',
		['mode'] = '3v3',
		['octane'] = '6f6a-ground-zero-gaming-vs-the-grogans',
		['parent'] = '',
		['stream'] = {
			['twitch'] = 'monyoce',
		},
		['twitch'] = 'monyoce',
		['winner'] = 1,
	},
	['opponentRecords'] = {
		{
			['icon'] = 'Ground Zero Gaming 2019 std.png',
			['name'] = 'Ground Zero Gaming',
			['placement'] = 1,
			['score'] = '3',
			['status'] = 'S',
			['template'] = 'ground zero gaming 2019',
			['type'] = 'team',
		},
		{
			['icon'] = 'Rocket_League.png',
			['name'] = 'The Grogans',
			['placement'] = 2,
			['score'] = '1',
			['status'] = 'S',
			['template'] = 'the grogans',
			['type'] = 'team',
		},
	},
	['playerRecords'] = {
		{},
		{}
	},
}

MatchTestConfig.EXAMPLE_MATCH_SC2 = {
	["bracketdata"] = {
		["bracketindex"] = 0,
		["bracketreset"] = "",
		["bracketsection"] = "lower",
		["header"] = "NA Tie-breaker (Bo5)",
		["quallose"] = "false",
		["qualskip"] = "0",
		["qualwin"] = "false",
		["sectionheader"] = "",
		["skipround"] = "0",
		["thirdplace"] = "",
		["tolower"] = "",
		["toupper"] = "",
		["type"] = "bracket",
	},
	["bracketid"] = "Liquipedia_1597534682",
	["cancelled"] = "false",
	["date"] = "2018-02-05T03:00:00+00:00",
	["dateexact"] = true,
	["extradata"] = {
		["featured"] = "false",
		["ffa"] = "false",
		["noQuery"] = "true",
	},
	["featured"] = "false",
	["finished"] = true,
	["game"] = "Legacy of the Void",
	["icon"] = "Intel Extreme Masters orig icon.png‎",
	["links"] = {
		["lrthread"] = "https://tl.net/forum/sc2-tournaments/530850-iem-xii-pyeongchang-day-one",
	},
	["liquipediatier"] = "1",
	["lrthread"] = "https://tl.net/forum/sc2-tournaments/530850-iem-xii-pyeongchang-day-one",
	["map1"] = {
		["$notEmpty$"] = "Catalyst",
		["date"] = "2018-02-05T03:00:00+00:00",
		["extradata"] = {
			["comment"] = "",
			["header"] = "",
			["isSubMatch"] = "false",
			["loserrace"] = "z",
			["noQuery"] = "true",
			["opponent1"] = "Cham",
			["opponent2"] = "Scarlett",
			["winnerrace"] = "z",
		},
		["game"] = "Legacy of the Void",
		["liquipediatier"] = "1",
		["map"] = "Catalyst LE",
		["mode"] = "1v1",
		["participants"] = {
			["1_1"] = {
				["faction"] = "z",
				["player"] = "Cham",
			},
			["2_1"] = {
				["faction"] = "z",
				["player"] = "Scarlett",
			},
		},
		["patch"] = "",
		["scores"] = {
			0,
			1,
		},
		["type"] = "Offline",
		["winner"] = "2",
	},
	["map2"] = {
		["$notEmpty$"] = "Blackpink",
		["date"] = "2018-02-05T03:00:00+00:00",
		["extradata"] = {
			["comment"] = "",
			["header"] = "",
			["isSubMatch"] = "false",
			["loserrace"] = "z",
			["noQuery"] = "true",
			["opponent1"] = "Cham",
			["opponent2"] = "Scarlett",
			["winnerrace"] = "z",
		},
		["game"] = "Legacy of the Void",
		["liquipediatier"] = "1",
		["map"] = "Blackpink LE",
		["mode"] = "1v1",
		["participants"] = {
			["1_1"] = {
				["faction"] = "z",
				["player"] = "Cham",
			},
			["2_1"] = {
				["faction"] = "z",
				["player"] = "Scarlett",
			},
		},
		["patch"] = "",
		["scores"] = {
			0,
			1,
		},
		["type"] = "Offline",
		["winner"] = "2",
	},
	["map3"] = {
		["$notEmpty$"] = "Neon Violet Square",
		["date"] = "2018-02-05T03:00:00+00:00",
		["extradata"] = {
			["comment"] = "",
			["header"] = "",
			["isSubMatch"] = "false",
			["loserrace"] = "z",
			["noQuery"] = "true",
			["opponent1"] = "Cham",
			["opponent2"] = "Scarlett",
			["winnerrace"] = "z",
		},
		["game"] = "Legacy of the Void",
		["liquipediatier"] = "1",
		["map"] = "Neon Violet Square LE",
		["mode"] = "1v1",
		["participants"] = {
			["1_1"] = {
				["faction"] = "z",
				["player"] = "Cham",
			},
			["2_1"] = {
				["faction"] = "z",
				["player"] = "Scarlett",
			},
		},
		["patch"] = "",
		["scores"] = {
			0,
			1,
		},
		["type"] = "Offline",
		["winner"] = "2",
	},
	["matchid"] = "R01-M001",
	["mode"] = "1_1",
	["noQuery"] = "true",
	["opponent1"] = {
		["extradata"] = {},
		["match2players"] = {
			{
				["displayname"] = "Cham",
				["extradata"] = {
					["faction"] = "z",
				},
				["flag"] = "Mexico",
				["name"] = "Cham",
			},
		},
		["name"] = "Cham",
		["placement"] = 2,
		["score"] = 0,
		["status"] = "S",
		["sumscore"] = 0,
		["type"] = "solo",
	},
	["opponent2"] = {
		["extradata"] = {},
		["match2players"] = {
			{
				["displayname"] = "Scarlett",
				["extradata"] = {
					["faction"] = "z",
				},
				["flag"] = "Canada",
				["name"] = "Scarlett",
			},
		},
		["name"] = "Scarlett",
		["placement"] = 1,
		["score"] = 3,
		["status"] = "S",
		["sumscore"] = 3,
		["type"] = "solo",
	},
	["parent"] = "",
	["series"] = "Intel Extreme Masters",
	["stream"] = {},
	["tickername"] = "IEM Season XII - PyeongChang",
	["tournament"] = "IEM Season XII - PyeongChang",
	["type"] = "Offline",
	["vod"] = "https://youtu.be/pIr5DbR9QC0",
	["winner"] = "2",
}

MatchTestConfig.EXPECTED_OUTPUT_AFTER_SPLIT_SC2 = {
	["gameRecords"] = {
		{
			["$notEmpty$"] = "Catalyst",
			["date"] = "2018-02-05T03:00:00+00:00",
			["extradata"] = {
				["comment"] = "",
				["header"] = "",
				["isSubMatch"] = "false",
				["loserrace"] = "z",
				["noQuery"] = "true",
				["opponent1"] = "Cham",
				["opponent2"] = "Scarlett",
				["winnerrace"] = "z",
			},
			["game"] = "Legacy of the Void",
			["liquipediatier"] = "1",
			["map"] = "Catalyst LE",
			["mode"] = "1v1",
			["participants"] = {
				["1_1"] = {
					["faction"] = "z",
					["player"] = "Cham",
				},
				["2_1"] = {
					["faction"] = "z",
					["player"] = "Scarlett",
				},
			},
			["patch"] = "",
			["scores"] = {
				0,
				1,
			},
			["type"] = "Offline",
			["winner"] = "2",
		},
		{
			["$notEmpty$"] = "Blackpink",
			["date"] = "2018-02-05T03:00:00+00:00",
			["extradata"] = {
				["comment"] = "",
				["header"] = "",
				["isSubMatch"] = "false",
				["loserrace"] = "z",
				["noQuery"] = "true",
				["opponent1"] = "Cham",
				["opponent2"] = "Scarlett",
				["winnerrace"] = "z",
			},
			["game"] = "Legacy of the Void",
			["liquipediatier"] = "1",
			["map"] = "Blackpink LE",
			["mode"] = "1v1",
			["participants"] = {
				["1_1"] = {
					["faction"] = "z",
					["player"] = "Cham",
				},
				["2_1"] = {
					["faction"] = "z",
					["player"] = "Scarlett",
				},
			},
			["patch"] = "",
			["scores"] = {
				0,
				1,
			},
			["type"] = "Offline",
			["winner"] = "2",
		},
		{
			["$notEmpty$"] = "Neon Violet Square",
			["date"] = "2018-02-05T03:00:00+00:00",
			["extradata"] = {
				["comment"] = "",
				["header"] = "",
				["isSubMatch"] = "false",
				["loserrace"] = "z",
				["noQuery"] = "true",
				["opponent1"] = "Cham",
				["opponent2"] = "Scarlett",
				["winnerrace"] = "z",
			},
			["game"] = "Legacy of the Void",
			["liquipediatier"] = "1",
			["map"] = "Neon Violet Square LE",
			["mode"] = "1v1",
			["participants"] = {
				["1_1"] = {
					["faction"] = "z",
					["player"] = "Cham",
				},
				["2_1"] = {
					["faction"] = "z",
					["player"] = "Scarlett",
				},
			},
			["patch"] = "",
			["scores"] = {
				0,
				1,
			},
			["type"] = "Offline",
			["winner"] = "2",
		},
	},
	["matchRecord"] = {
		["bracketdata"] = {
			["bracketindex"] = 0,
			["bracketreset"] = "",
			["bracketsection"] = "lower",
			["header"] = "NA Tie-breaker (Bo5)",
			["quallose"] = "false",
			["qualskip"] = "0",
			["qualwin"] = "false",
			["sectionheader"] = "",
			["skipround"] = "0",
			["thirdplace"] = "",
			["tolower"] = "",
			["toupper"] = "",
			["type"] = "bracket",
		},
		["bracketid"] = "Liquipedia_1597534682",
		["cancelled"] = "false",
		["date"] = "2018-02-05T03:00:00+00:00",
		["dateexact"] = true,
		["extradata"] = {
			["featured"] = "false",
			["ffa"] = "false",
			["noQuery"] = "true",
		},
		["featured"] = "false",
		["finished"] = true,
		["game"] = "Legacy of the Void",
		["icon"] = "Intel Extreme Masters orig icon.png‎",
		["links"] = {
			["lrthread"] = "https://tl.net/forum/sc2-tournaments/530850-iem-xii-pyeongchang-day-one",
		},
		["liquipediatier"] = "1",
		["lrthread"] = "https://tl.net/forum/sc2-tournaments/530850-iem-xii-pyeongchang-day-one",
		["matchid"] = "R01-M001",
		["mode"] = "1_1",
		["noQuery"] = "true",
		["parent"] = "",
		["series"] = "Intel Extreme Masters",
		["stream"] = {},
		["tickername"] = "IEM Season XII - PyeongChang",
		["tournament"] = "IEM Season XII - PyeongChang",
		["type"] = "Offline",
		["vod"] = "https://youtu.be/pIr5DbR9QC0",
		["winner"] = "2",
	},
	["opponentRecords"] = {
		{
			["extradata"] = {},
			["name"] = "Cham",
			["placement"] = 2,
			["score"] = 0,
			["status"] = "S",
			["sumscore"] = 0,
			["type"] = "solo",
		},
		{
			["extradata"] = {},
			["name"] = "Scarlett",
			["placement"] = 1,
			["score"] = 3,
			["status"] = "S",
			["sumscore"] = 3,
			["type"] = "solo",
		},
	},
	["playerRecords"] = {
		{
			{
				["displayname"] = "Cham",
				["extradata"] = {
					["faction"] = "z",
				},
				["flag"] = "Mexico",
				["name"] = "Cham",
			},
		},
		{
			{
				["displayname"] = "Scarlett",
				["extradata"] = {
					["faction"] = "z",
				},
				["flag"] = "Canada",
				["name"] = "Scarlett",
			},
		},
	},
}

return MatchTestConfig
