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

return MatchTestConfig
