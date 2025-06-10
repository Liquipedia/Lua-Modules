---
-- @Liquipedia
-- page=Module:Opponent/testcases/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Opponent = Lua.import('Module:Opponent')

return {
	emptyTeam = {type = Opponent.team, template = ''},
	blankLiteral = {type = Opponent.literal, name = ''},
	blankTeam = {type = Opponent.team, template = 'tbd'},
	blankSolo = {type = Opponent.solo, players = {{displayName = ''}}},
	blankDuo = {type = Opponent.duo, players = {{displayName = ''}, {displayName = ''}}},
	tbdLiteral = {type = Opponent.literal, name = 'TBD'},
	tbdSolo = {type = Opponent.solo, players = {{displayName = 'TBD'}}},
	tbdDuo = {type = Opponent.duo, players = {{displayName = 'TBD'}, {displayName = 'TBD'}}},
	tbdTeam = {type = Opponent.team, template = 'tbd'},
	filledLiteral = {type = Opponent.literal, name = 'test'},
	filledTeam = {type = Opponent.team, template = 'test'},
	filledSolo = {type = Opponent.solo, players = {{displayName = 'test'}}},
	filledDuo = {type = Opponent.duo, players = {{displayName = 'test'}, {displayName = 'test2'}}},
	byeLiteral = {type = Opponent.literal, name = 'BYE'},
	byeTeam = {type = Opponent.team, template = 'bye'},
	exampleMatch2RecordTeam = {
		['extradata'] = {
		},
		['icon'] = 'Exon feb 2020 logo std.png',
		['icondark'] = 'Exon feb 2020 logo std.png',
		['match2id'] = 'nfqp56Ms10_R01-M001',
		['match2opponentid'] = '1',
		['match2players'] = {
			{
				['displayname'] = 'Ryan',
				['extradata'] = {
					['faction'] = 'p',
					['position'] = 1,
				},
				['flag'] = 'United States',
				['match2id'] = 'nfqp56Ms10_R01-M001',
				['match2opponentid'] = '1',
				['match2playerid'] = '1',
				['name'] = 'Ryan',
				['namespace'] = '0',
				['objectname'] = '100077_nfqp56Ms10_R01-M001_m2o_01_m2p_01',
				['pageid'] = '100077',
				['pagename'] = 'Team_eXoN_vs_Archangel_Gaming',
			},
		},
		['name'] = 'Team_eXoN',
		['namespace'] = '0',
		['objectname'] = '100077_nfqp56Ms10_R01-M001_m2o_01',
		['pageid'] = '100077',
		['pagename'] = 'Team_eXoN_vs_Archangel_Gaming',
		['placement'] = '1',
		['score'] = '4',
		['status'] = 'S',
		['template'] = 'exon march 2020',
		['type'] = 'team',
	},
	exampleMatch2RecordSolo = {
		['extradata'] = {
		},
		['icon'] = '',
		['icondark'] = '',
		['match2id'] = '2PoEDmWYXd_R01-M001',
		['match2opponentid'] = '1',
		['match2players'] = {
			{
				['displayname'] = 'Krystianer',
				['extradata'] = {
					['faction'] = 'p',
				},
				['flag'] = 'Poland',
				['match2id'] = '2PoEDmWYXd_R01-M001',
				['match2opponentid'] = '1',
				['match2playerid'] = '1',
				['name'] = 'Krystianer',
				['namespace'] = '0',
				['objectname'] = '100009_2PoEDmWYXd_R01-M001_m2o_01_m2p_01',
				['pageid'] = '100009',
				['pagename'] = 'IndyK_Trovo_Weekly/8',
			},
		},
		['name'] = 'Krystianer',
		['namespace'] = '0',
		['objectname'] = '100009_2PoEDmWYXd_R01-M001_m2o_01',
		['pageid'] = '100009',
		['pagename'] = 'IndyK_Trovo_Weekly/8',
		['placement'] = '1',
		['score'] = '3',
		['status'] = 'S',
		['template'] = '',
		['type'] = 'solo',
	},
	exampleMatch2RecordDuo = {
		['extradata'] = {
		},
		['icon'] = '',
		['icondark'] = '',
		['match2id'] = 'lr77upsRc9_R01-M001',
		['match2opponentid'] = '1',
		['match2players'] = {
			{
				['displayname'] = 'Semper',
				['extradata'] = {
					['faction'] = 'p',
				},
				['flag'] = 'Canada',
				['match2id'] = 'lr77upsRc9_R01-M001',
				['match2opponentid'] = '1',
				['match2playerid'] = '1',
				['name'] = 'Semper',
				['namespace'] = '0',
				['objectname'] = '100233_lr77upsRc9_R01-M001_m2o_01_m2p_01',
				['pageid'] = '100233',
				['pagename'] = 'Sugar_2v2_Cup/12',
			},
			{
				['displayname'] = 'Jig',
				['extradata'] = {
					['faction'] = 'z',
				},
				['flag'] = 'Canada',
				['match2id'] = 'lr77upsRc9_R01-M001',
				['match2opponentid'] = '1',
				['match2playerid'] = '2',
				['name'] = 'Jig',
				['namespace'] = '0',
				['objectname'] = '100233_lr77upsRc9_R01-M001_m2o_01_m2p_02',
				['pageid'] = '100233',
				['pagename'] = 'Sugar_2v2_Cup/12',
			},
		},
		['name'] = 'Semper / Jig',
		['namespace'] = '0',
		['objectname'] = '100233_lr77upsRc9_R01-M001_m2o_01',
		['pageid'] = '100233',
		['pagename'] = 'Sugar_2v2_Cup/12',
		['placement'] = '2',
		['score'] = '0',
		['status'] = 'S',
		['template'] = '',
		['type'] = 'duo',
	},
	exampleMatch2RecordLiteral = {
		['extradata'] = {
		},
		['icon'] = '',
		['icondark'] = '',
		['match2id'] = 'uL5vthPxZR_0025',
		['match2opponentid'] = '2',
		['match2players'] = {
		},
		['name'] = '',
		['namespace'] = '0',
		['objectname'] = '100657_uL5vthPxZR_0025_m2o_02',
		['pageid'] = '100657',
		['pagename'] = 'Belong_Online_Cup/2',
		['placement'] = '2',
		['score'] = '-1',
		['status'] = 'L',
		['template'] = '',
		['type'] = 'literal',
	},
}
