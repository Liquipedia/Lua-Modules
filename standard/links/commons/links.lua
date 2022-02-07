---
-- @Liquipedia
-- wiki=commons
-- page=Module:Links
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local CustomData = Lua.loadDataIfExists('Module:Links/CustomData', {})

local Links = {}

local _PREFIXES = {
	['5ewin'] = {'https://arena.5eplay.com/tournament/'},
	abiosgaming = {'https://abiosgaming.com/tournaments/'},
	afreeca = {'http://afreecatv.com/'},
	aoezone = {'https://aoezone.net/'},
	['ask-fm'] = {'https://ask.fm/'},
	battlefy = {'https://www.battlefy.com/'},
	booyah = {'https://booyah.live/'},
	bracket = {''},
	challengermode = {'https://www.challengermode.com/tournaments/'},
	challonge = {
		'',
		player = 'https://challonge.com/users/',
	},
	cybergamer = {'https://au.cybergamer.com/profile/'},
	datdota = {
		'',
		player = 'https://datdota.com/players/',
		team = 'https://datdota.com/teams/'
	},
	discord = {'https://discord.gg/'},
	dlive = {'https://www.dlive.tv/'},
	dotabuff = {
		'',
		player = 'https://dotabuff.com/esports/players/',
		team = 'https://dotabuff.com/esports/teams/'
	},
	douyu = {'https://www.douyu.com/'},
	esea = {'https://play.esea.net/events/'},
	['esea-d'] = {'https://play.esea.net/league/standings?divisionId='},
	esl = {
		'',
		team = 'https://play.eslgaming.com/team/',
		player = 'https://play.eslgaming.com/player/',
	},
	facebook = {'https://facebook.com/'},
	['facebook-gaming'] = {'https://fb.gg/'},
	faceit = {
		'',
		team = 'https://www.faceit.com/teams/',
		player = 'https://www.faceit.com/players/',
	},
	['faceit-c'] = {'https://www.faceit.com/en/championship/'},
	fanclub = {''},
	gamersclub = {'https://csgo.gamersclub.gg/campeonatos/csgo/'},
	gplus = {'http://plus.google.com/-plus'},
	halodatahive = {
		'https://halodatahive.com/Tournament/Detail/',
		team = 'https://halodatahive.com/Team/Detail/',
		player = 'https://halodatahive.com/Player/Detail/',
	},
	home = {''},
	huomaotv = {'http://www.huomao.com/'},
	huyatv = {'https://www.huya.com/'},
	instagram = {'https://www.instagram.com/'},
	loco = {'https://loco.gg/streamers/'},
	matcherino = {'https://matcherino.com/tournaments/'},
	matcherinolink = {'https://matcherino.com/t/'},
	mildom = {'https://www.mildom.com/'},
	octane = {'https://octane.gg/events/'},
	patreon = {'https://www.patreon.com/'},
	playlist = {''},
	reddit = {'https://www.reddit.com/user/'},
	rulebook = {''},
	rules = {''},
	site = {''},
	sk = {'https://sk-gaming.com/member/'},
	['smash-gg'] = {'https://smash.gg/'},
	snapchat = {'https://www.snapchat.com/add/'},
	sostronk = {'https://www.sostronk.com/tournament/'},
	steam = {'https://steamcommunity.com/id/'},
	steamalternative = {'https://steamcommunity.com/profiles/'},
	stratz = {
		'',
		player = 'https://stratz.com/player/'
	},
	stream = {''},
	telegram = {'https://t.me/'},
	tiktok = {'https://tiktok.com/@'},
	tlprofile = {'https://www.teamliquid.net/forum/profile.php?user='},
	tlstream = {'https://www.teamliquid.net/video/streams/'},
	toornament = {'https://www.toornament.com/tournaments/'},
	trovo = {'https://trovo.live/'},
	twitch = {'https://www.twitch.tv/'},
	twitter = {'https://twitter.com/'},
	vidio = {'https://www.vidio.com/@'},
	vk = {'https://www.vk.com/'},
	vlr = {
		'https://www.vlr.gg/event/',
		team = 'https://www.vlr.gg/team/',
		player = 'https://www.vlr.gg/player/'
	},
	website = {''},
	weibo = {'https://weibo.com/'},
	youtube = {'https://www.youtube.com/'},
	zhangyutv = {'http://www.zhangyu.tv/'},
}

_PREFIXES = Table.merge(_PREFIXES, CustomData.prefixes or {})

local _SUFFIXES = {
	['faceit-c'] = '/event',
}

_SUFFIXES = Table.merge(_SUFFIXES, CustomData.suffixes or {})

function Links.transform(links)
	return {
		['5ewin'] = links['5ewin'],
		abiosgaming = links.abiosgaming,
		afreeca = links.afreeca,
		afreeca2 = links.afreeca2,
		aligulac = links.aligulac,
		aoezone = links.aoezone,
		aoezone2 = links.aoezone2,
		aoezone3 = links.aoezone3,
		aoezone4 = links.aoezone4,
		aoezone5 = links.aoezone5,
		['ask-fm'] = links.askfm,
		battlefy = links.battlefy,
		battlefy2 = links.battlefy2,
		battlefy3 = links.battlefy3,
		booyah = links.booyah,
		bracket = links.bracket,
		bracket2 = links.bracket2,
		bracket3 = links.bracket3,
		bracket4 = links.bracket4,
		bracket5 = links.bracket5,
		bracket6 = links.bracket6,
		bracket7 = links.bracket7,
		challengermode = links.challengermode,
		challengermode2 = links.challengermode2,
		challonge = links.challonge,
		challonge2 = links.challonge2,
		challonge3 = links.challonge3,
		challonge4 = links.challonge4,
		challonge5 = links.challonge5,
		cybergamer = links.cybergamer,
		datdota = links.datdota,
		discord = links.discord,
		dlive = links.dlive,
		dotabuff = links.dotabuff,
		douyu = links.douyu,
		esea = links.esea,
		['esea-d'] = links['esea-d'],
		esl = links.eslgaming or links.esl,
		esl2 = links.eslgaming2 or links.esl2,
		esl3 = links.eslgaming3 or links.esl3,
		esl4 = links.eslgaming4 or links.esl4,
		esl5 = links.eslgaming5 or links.esl5,
		facebook = links.facebook,
		facebook2 = links.facebook2,
		['facebook-gaming'] = links['facebook-gaming'] or links.fbgg,
		faceit = links.faceit,
		['faceit-c'] = links['faceit-c'],
		['faceit-c2'] = links['faceit-c2'],
		fanclub = links.fanclub,
		gamersclub = links.gamersclub,
		gamersclub2 = links.gamersclub2,
		halodatahive = links.halodatahive,
		home = links.website or links.web or links.site or links.url,
		home2 = links.website2 or links.web2 or links.site2 or links.url2,
		huyatv = links.huyatv,
		huyatv2 = links.huyatv2,
		instagram = links.instagram,
		instagram2 = links.instagram2,
		loco = links.loco,
		matcherino = links.matcherino,
		matcherinolink = links.matcherinolink,
		mildom = links.mildom,
		octane = links.octane,
		patreon = links.patreon,
		playlist = links.playlist,
		reddit = links.reddit,
		rules = links.rules or links.rulebook,
		['smash-gg'] = links.smashgg,
		snapchat = links.snapchat,
		sostronk = links.sostronk,
		steam = links.steam,
		steamalternative = links.steamalternative,
		stratz = links.stratz,
		stream = links.stream,
		stream2 = links.stream2,
		tiktok = links.tiktok,
		tlprofile = links.tlprofile,
		tlstream = links.tlstream,
		toornament = links.toornament,
		toornament2 = links.toornament2,
		toornament3 = links.toornament3,
		trovo = links.trovo,
		trovo2 = links.trovo2,
		twitch = links.twitch,
		twitch2 = links.twitch2,
		twitch3 = links.twitch3,
		twitch4 = links.twitch4,
		twitch5 = links.twitch5,
		twitter = links.twitter,
		twitter2 = links.twitter2,
		vidio = links.vidio,
		vk = links.vk,
		vlr = links.vlr,
		weibo = links.weibo,
		youtube = links.youtube,
		youtube2 = links.youtube2,
		youtube3 = links.youtube3,
		youtube4 = links.youtube4,
		youtube5 = links.youtube5,
	}
end

function Links.makeFullLink(platform, id, variant)
	if id == nil or id == '' then
		return ''
	end

	local prefixData = _PREFIXES[platform]

	if not prefixData then
		return ''
	end

	local prefix = prefixData[variant] or prefixData[1]

	return prefix .. id .. (_SUFFIXES[platform] or '')
end

function Links.makeFullLinksForTableItems(links, variant)
	for key, item in pairs(links) do
		links[key] = Links.makeFullLink(Links._removeAppendedNumber(key), item, variant)
	end
	return links
end

--remove appended number
--needed because the link icons require e.g. 'esl' instead of 'esl2'
function Links._removeAppendedNumber(key)
	return string.gsub(key, '%d$', '')
end

return Class.export(Links, {frameOnly = true})
