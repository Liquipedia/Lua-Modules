---
-- @Liquipedia
-- page=Module:MatchExternalLinks
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- {} represents where a dot should be placed between links in MatchSummary footer

return {
	{
		name = 'preview',
		icon = 'Preview Icon32.png',
		prefixLink = '',
		label = 'Preview',
	},
	{
		name = 'lrthread',
		icon = 'LiveReport32.png',
		prefixLink = '',
		label = 'Live Report Thread',
	},
	{},
	{
		name = 'cevo',
		icon = 'CEVO icon.png',
		prefixLink = 'http://cevo.com/event/',
		label = 'Matchpage and Stats on CEVO',
		max = 2,
	},
	{
		name = 'esl',
		icon = 'ESL 2019 icon lightmode.png',
		iconDark = 'ESL 2019 icon darkmode.png',
		prefixLink = 'https://play.eslgaming.com/match/',
		label = 'Matchpage and Stats on ESL Play',
		isMapStats = true
	},
	{
		name = 'esea',
		icon = 'ESEA icon.png',
		prefixLink = 'https://play.esea.net/match/',
		label = 'Matchpage and Stats on ESEA',
		isMapStats = true
	},
	{
		name = 'faceit',
		icon = 'FACEIT-icon.png',
		prefixLink = 'https://www.faceit.com/en/match/room/',
		label = 'Match Room and Stats on FACEIT',
		isMapStats = true
	},
	{
		name = 'esportal',
		icon = 'Esportal icon32.png',
		prefixLink = 'https://esportal.com/match/',
		label = 'Matchpage and Stats on Esportal',
		isMapStats = true
	},
	{
		name = 'esplay',
		icon = 'Esplay icon allmode.png',
		prefixLink = 'https://esplay.com/m/',
		label = 'Matchpage and Stats on Esplay',
		isMapStats = true
	},
	{
		name = 'sltv',
		icon = 'StarLadder icon.png',
		prefixLink = 'http://csgo.starladder.tv/match/',
		label = 'Matchpage and Stats on SLTV',
	},
	{
		name = 'sltv-e',
		icon = 'StarLadder icon.png',
		prefixLink = 'https://starladder.com/en/events/',
		label = 'Matchpage and Stats on SLTV',
	},
	{
		name = 'lpl-old',
		icon = 'LPL Play icon.png',
		prefixLink = 'https://old.letsplay.live/match/',
		label = 'Matchpage on LPL Play',
	},
	{
		name = 'lpl',
		icon = 'letsplay.live 2024 icon lightmode.png',
		iconDark = 'letsplay.live 2024 icon darkmode.png',
		prefixLink = 'https://gg.letsplay.live/report-score/',
		label = 'Matchpage on letsplay.live',
	},
	{
		name = 'epiclan',
		icon = 'EPIC.LAN 2021 icon allmode.png',
		prefixLink = 'https://tournaments.epiclan.co.uk/tournaments/',
		label = 'Matchpage on epic.LAN',
	},
	{
		name = 'pinger-csgo',
		icon = 'Pinger icon lightmode.png',
		iconDark = 'Pinger icon darkmode.png',
		prefixLink = 'https://pinger.kz/matches/csgo/',
		label = 'Matchpage and Stats on Pinger',
	},
	{
		name = 'pinger',
		icon = 'Pinger icon lightmode.png',
		iconDark = 'Pinger icon darkmode.png',
		prefixLink = 'https://pinger.kz/tournaments/cs2/event/matches/',
		label = 'Matchpage and Stats on Pinger',
	},
	{
		name = '99damage',
		icon = '99Damage_2021_allmode.png',
		prefixLink = 'https://csgo.99damage.de/de/matches/',
		label = '99Damage Matchpage',
		stats = {'99liga'}
	},
	{
		name = '99liga',
		icon = '99Damage_2021_allmode.png',
		prefixLink = 'https://liga.99damage.de/de/leagues/matches/',
		label = 'Matchpage and Stats on 99Liga',
	},
	{
		name = 'sostronk',
		icon = 'SoStronk lightmode.png',
		iconDark = 'SoStronk darkmode.png',
		prefixLink = 'https://www.sostronk.com/match/',
		label = 'Matchpage and Stats on SoStronk',
		isMapStats = true
	},
	{
		name = '5eplay',
		icon = '5EPlay icon.png',
		prefixLink = 'https://www.5eplay.com/session/',
		label = '5EPlay Matchpage',
		stats = {'5ewin', '5earena'}
	},
	{
		name = '5ewin',
		icon = '5ewin icon.png',
		prefixLink = 'https://arena.5eplay.com/data/match/',
		label = 'Stats on 5Ewin',
		isMapStats = true
	},
	{
		name = '5earena',
		icon = '5E Arena icon.png',
		prefixLink = 'https://www.5earena.com/gamedata/matchboard/',
		label = 'Stats on 5E Arena',
		isMapStats = true
	},
	{
		name = 'b5csgo',
		icon = 'b5csgo icon.png',
		prefixLink = 'https://www.b5csgo.com/customMatchBoard/',
		label = 'Stats on B5csgo',
		isMapStats = true
	},
	{
		name = 'wanmei',
		icon = 'Wanmei icon.png',
		prefixLink = 'http://pvpmatchapi.wanmei.com/csgo/match/',
		label = 'Stats on Wanmei',
		isMapStats = true
	},
	{
		name = 'challengeme',
		icon = 'ChallengeMe icon.png',
		prefixLink = 'https://www.challengeme.gg/arena/match/',
		label = 'Matchpage and Stats on ChallengeMe',
		isMapStats = true
	},
	{
		name = 'challengermode',
		icon = 'Challengermode icon.png',
		prefixLink = 'https://www.challengermode.com/games/',
		label = 'Matchpage on Challengermode',
		isMapStats = true
	},
	{
		name = 'gotfrag',
		icon = 'GotFrag icon.png',
		prefixLink = '',
		label = 'Matchpage and Stats on GotFrag',
		isMapStats = true
	},
	{
		name = 'draft5',
		icon = 'Draft5 icon lightmode.png',
		iconDark = 'Draft5 icon darkmode.png',
		prefixLink = 'https://draft5.gg/partida/',
		label = 'Draft5 Matchpage',
		stats = {'gamersclub', 'gamersclublobby', 'coliseum'}
	},
	{
		name = 'gamersclub',
		icon = 'Gamers Club icon lightmode.png',
		iconDark = 'Gamers Club icon darkmode.png',
		prefixLink = 'https://gamersclub.com.br/tournaments/cs/',
		label = 'Matchpage and Stats on Gamers Club',
		isMapStats = true
	},
	{
		name = 'gamersclublobby',
		icon = 'Gamers Club icon lightmode.png',
		iconDark = 'Gamers Club icon darkmode.png',
		prefixLink = 'https://gamersclub.com.br/lobby/partida/',
		label = 'Matchpage and Stats on Gamers Club',
		isMapStats = true
	},
	{
		name = 'coliseum',
		icon = 'Coliseum icon.png',
		prefixLink = 'https://coliseum.gg/tournament/',
		label = 'Matchpage and Stats on Coliseum',
		isMapStats = true
	},
	{},
	{
		name = 'hltvlegacy',
		icon = 'HLTV icon.png',
		prefixLink = 'https://www.hltv.org/legacy/match/',
		label = 'HLTV Matchpage',
		stats = {'legacystats', 'stats'}
	},
	{
		name = 'hltv',
		icon = 'HLTV icon.png',
		prefixLink = 'https://www.hltv.org/matches/',
		suffixLink = '/match',
		label = 'HLTV Matchpage',
		max = 2,
		stats = {'legacystats', 'stats'}
	},
	{
		name = 'legacystats',
		icon = 'stats',
		prefixLink = 'https://www.hltv.org/legacystats/match/mapstatsid/',
		label = 'Stats on HLTV',
		isMapStats = true
	},
	{
		name = 'stats',
		icon = 'stats',
		prefixLink = 'https://www.hltv.org/?pageid=188&matchid=',
		label = 'Stats on HLTV',
		isMapStats = true
	},
	{},
	{
		name = 'cstats',
		icon = 'stats',
		prefixLink = '',
		label = 'Matchpage and Stats',
		isMapStats = true
	}
}
