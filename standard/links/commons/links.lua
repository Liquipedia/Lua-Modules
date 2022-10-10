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
local CustomData = Lua.loadDataIfExists('Module:Links/CustomData') or {}

local Links = {}

local _PREFIXES = {
	['5ewin'] = {
		'https://arena.5eplay.com/tournament/',
		player = 'https://arena.5eplay.com/data/player/',
		team = 'https://arena.5eplay.com/team/'
	},
	abiosgaming = {'https://abiosgaming.com/tournaments/'},
	apexlegendsstatus = {'https://apexlegendsstatus.com/profile/uid/PC/'},
	afreeca = {'http://afreecatv.com/'},
	aoezone = {'https://aoezone.net/'},
	['ask-fm'] = {'https://ask.fm/'},
	b5csgo = {
		'',
		player = 'https://www.b5csgo.com/personalCenter/',
		team = 'https://www.b5csgo.com/clan/'
	},
	battlefy = {'https://www.battlefy.com/'},
	bilibili = {'https://space.bilibili.com/'},
	['bilibili-stream'] = {'https://live.bilibili.com/'},
	booyah = {'https://booyah.live/'},
	bracket = {''},
	challengermode = {'https://www.challengermode.com/tournaments/'},
	challonge = {
		'',
		player = 'https://challonge.com/users/',
	},
	datdota = {
		'https://www.datdota.com/leagues/',
		player = 'https://www.datdota.com/players/',
		team = 'https://www.datdota.com/teams/'
	},
	daumcafe = {'http://cafe.daum.net/'},
	discord = {'https://discord.gg/'},
	dlive = {'https://www.dlive.tv/'},
	dotabuff = {
		'https://www.dotabuff.com/esports/leagues/',
		player = 'https://www.dotabuff.com/esports/players/',
		team = 'https://www.dotabuff.com/esports/teams/'
	},
	douyu = {'https://www.douyu.com/'},
	esea = {
		'https://play.esea.net/events/',
		player = 'https://play.esea.net/users/',
		team = 'https://play.esea.net/teams/'
	},
	['esea-d'] = {'https://play.esea.net/league/standings?divisionId='},
	esl = {
		'',
		team = 'https://play.eslgaming.com/team/',
		player = 'https://play.eslgaming.com/player/',
	},
	esportal = {'https://esportal.com/tournament/'},
	facebook = {'https://facebook.com/'},
	['facebook-gaming'] = {'https://fb.gg/'},
	faceit = {
		'',
		team = 'https://www.faceit.com/en/teams/',
		player = 'https://www.faceit.com/en/players/',
	},
	['faceit-c'] = {'https://www.faceit.com/en/championship/'},
	['faceit-hub'] = {'https://www.faceit.com/en/hub/'},
	['faceit-org'] = {'https://www.faceit.com/en/organizers/'},
	factor = {
		'',
		team = 'https://www.factor.gg/team/',
		player = 'https://www.factor.gg/player/',
	},
	fanclub = {''},
	gamersclub = {
		'https://csgo.gamersclub.gg/campeonatos/csgo/',
		team = 'https://csgo.gamersclub.gg/team/',
		player = 'https://csgo.gamersclub.gg/jogador/',
	},
	gplus = {'http://plus.google.com/-plus'},
	halodatahive = {
		'https://halodatahive.com/Tournament/Detail/',
		team = 'https://halodatahive.com/Team/Detail/',
		player = 'https://halodatahive.com/Player/Detail/',
	},
	home = {''},
	huyatv = {'https://www.huya.com/'},
	iccup = {'http://www.iccup.com/starcraft/gamingprofile/'},
	instagram = {'https://www.instagram.com/'},
	kuaishou = {'https://live.kuaishou.com/u/'},
	letsplaylive = {'https://letsplay.live/profile/'},
	loco = {'https://loco.gg/streamers/'},
	matcherino = {'https://matcherino.com/tournaments/'},
	matcherinolink = {'https://matcherino.com/t/'},
	mildom = {'https://www.mildom.com/'},
	octane = {'https://octane.gg/events/'},
	patreon = {'https://www.patreon.com/'},
	playlist = {''},
	reddit = {'https://www.reddit.com/user/'},
	rulebook = {''},
	rulebook2 = {''},
	rules = {''},
	rules2 = {''},
	['siege-gg'] = {
		'https://siege.gg/competitions/',
		team = 'https://siege.gg/teams/',
		player = 'https://siege.gg/players/',
	},
	site = {''},
	sk = {'https://sk-gaming.com/member/'},
	['smash-gg'] = {'https://smash.gg/'},
	snapchat = {'https://www.snapchat.com/add/'},
	sostronk = {'https://www.sostronk.com/tournament/'},
	steam = {'https://steamcommunity.com/id/'},
	privsteam = {'https://steamcommunity.com/groups/'},
	pubsteam = {'https://steamcommunity.com/groups/'},
	steamalternative = {'https://steamcommunity.com/profiles/'},
	stratz = {
		'',
		player = 'https://stratz.com/player/'
	},
	stream = {''},
	telegram = {'https://t.me/'},
	tiktok = {'https://tiktok.com/@'},
	tlpd = {''},
	tlpdint = {
		'',
		team = 'https://tl.net/tlpd/international/teams/',
		player = 'https://tl.net/tlpd/international/players/',
	},
	tlpdkr = {
		'',
		team = 'https://tl.net/tlpd/korean/teams/',
		player = 'https://tl.net/tlpd/korean/players/',
	},
	tlpdsospa = {
		'',
		team = 'https://tl.net/tlpd/sospa/teams/',
		player = 'https://tl.net/tlpd/sospa/players/',
	},
	tlprofile = {'https://tl.net/forum/profile.php?user='},
	tlstream = {'https://tl.net/video/streams/'},
	toornament = {'https://www.toornament.com/tournaments/'},
	['trackmania-io'] = {
		'https://trackmania.io/#/competitions/comp/',
		player = 'https://trackmania.io/#/player/',
	},
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
	iccup = '.html',
	['faceit-c'] = '/',
	['faceit-hub'] = '/',
}

_SUFFIXES = Table.merge(_SUFFIXES, CustomData.suffixes or {})

function Links.transform(links)
	return {
		['5ewin'] = links['5ewin'],
		abiosgaming = links.abiosgaming,
		apexlegendsstatus = links.apexlegendsstatus,
		afreeca = links.afreeca,
		afreeca2 = links.afreeca2,
		aligulac = links.aligulac,
		aligulac2 = links.aligulac2,
		aoezone = links.aoezone,
		aoezone2 = links.aoezone2,
		aoezone3 = links.aoezone3,
		aoezone4 = links.aoezone4,
		aoezone5 = links.aoezone5,
		['ask-fm'] = links.askfm,
		battlefy = links.battlefy,
		battlefy2 = links.battlefy2,
		battlefy3 = links.battlefy3,
		bilibili = links.bilibili,
		['bilibili-stream'] = links['bilibili-stream'],
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
		datdota = links.datdota,
		daumcafe = links.daumcafe,
		discord = links.discord,
		dlive = links.dlive,
		dotabuff = links.dotabuff,
		douyu = links.douyu or links.douyutv,
		esea = links.esea,
		esea2 = links.esea2,
		['esea-d'] = links['esea-d'],
		esl = links.eslgaming or links.esl,
		esl2 = links.eslgaming2 or links.esl2,
		esl3 = links.eslgaming3 or links.esl3,
		esl4 = links.eslgaming4 or links.esl4,
		esl5 = links.eslgaming5 or links.esl5,
		esportal = links.esportal,
		facebook = links.facebook,
		facebook2 = links.facebook2,
		['facebook-gaming'] = links['facebook-gaming'] or links.fbgg,
		faceit = links.faceit,
		['faceit-c'] = links['faceit-c'],
		['faceit-c2'] = links['faceit-c2'],
		['faceit-hub'] = links['faceit-hub'],
		['faceit-org'] = links['faceit-org'],
		factor = links.factor,
		fanclub = links.fanclub,
		gamersclub = links.gamersclub,
		gamersclub2 = links.gamersclub2,
		halodatahive = links.halodatahive,
		home = links.website or links.web or links.site or links.url,
		home2 = links.website2 or links.web2 or links.site2 or links.url2,
		huyatv = links.huyatv or links.huya,
		huyatv2 = links.huyatv2 or links.huya2,
		iccup = links.iccup,
		instagram = links.instagram,
		instagram2 = links.instagram2,
		kuaishou = links.kuaishou,
		letsplaylive = links.letsplaylive or links.cybergamer,
		loco = links.loco,
		matcherino = links.matcherino,
		matcherinolink = links.matcherinolink,
		mildom = links.mildom,
		octane = links.octane,
		patreon = links.patreon,
		playlist = links.playlist,
		privsteam = links.privsteam,
		pubsteam = links.pubsteam,
		reddit = links.reddit,
		rules = links.rules or links.rulebook,
		rules2 = links.rules2 or links.rulebook2,
		['siege-gg'] = links.siegegg,
		['smash-gg'] = links.smashgg,
		snapchat = links.snapchat,
		sk = links.sk,
		sostronk = links.sostronk,
		steam = links.steam,
		steamalternative = links.steamalternative,
		stratz = links.stratz,
		stream = links.stream,
		stream2 = links.stream2,
		tiktok = links.tiktok,
		tlpd = links.tlpd,
		tlpdint = links.tlpdint,
		tlpdkr = links.tlpdkr,
		tlpdsospa = links.tlpdsospa,
		tlprofile = links.tlprofile,
		tlstream = links.tlstream,
		toornament = links.toornament,
		toornament2 = links.toornament2,
		toornament3 = links.toornament3,
		['trackmania-io'] = links['trackmania-io'],
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
		weibo2 = links.weibo2,
		youtube = links.youtube,
		youtube2 = links.youtube2,
		youtube3 = links.youtube3,
		youtube4 = links.youtube4,
		youtube5 = links.youtube5,
		zhangyutv = links.zhangyutv,
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
