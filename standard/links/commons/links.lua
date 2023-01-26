---
-- @Liquipedia
-- wiki=commons
-- page=Module:Links
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local CustomData = Lua.loadDataIfExists('Module:Links/CustomData') or {}

local Links = {}

local PREFIXES = {
	['5ewin'] = {
		'https://arena.5eplay.com/tournament/',
		player = 'https://arena.5eplay.com/data/player/',
		team = 'https://arena.5eplay.com/team/',
	},
	abiosgaming = {'https://abiosgaming.com/tournaments/'},
	apexlegendsstatus = {'https://apexlegendsstatus.com/profile/uid/PC/'},
	afreeca = {
		'http://afreecatv.com/',
		stream = 'https://play.afreecatv.com/',
	},
	aoezone = {'https://aoezone.net/'},
	['ask-fm'] = {'https://ask.fm/'},
	b5csgo = {
		'',
		player = 'https://www.b5csgo.com/personalCenter/',
		team = 'https://www.b5csgo.com/clan/'
	},
	battlefy = {'https://www.battlefy.com/'},
	bilibili = {
		'https://space.bilibili.com/',
		stream = 'https://live.bilibili.com/',
	},
	['bilibili-stream'] = {'https://live.bilibili.com/'},
	booyah = {'https://booyah.live/'},
	bracket = {''},
	cc = {'https://cc.163.com/'},
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
	nimotv = {'https://www.nimo.tv/'},
	openrec = {'https://www.openrec.tv/live/'},
	patreon = {'https://www.patreon.com/'},
	playlist = {''},
	reddit = {'https://www.reddit.com/user/'},
	royaleapi = {'https://royaleapi.com/player/'},
	rulebook = {''},
	rules = {''},
	shift = {'https://www.shiftrle.gg/events/'},
	['siege-gg'] = {
		'https://siege.gg/competitions/',
		team = 'https://siege.gg/teams/',
		player = 'https://siege.gg/players/',
	},
	site = {''},
	sk = {'https://sk-gaming.com/member/'},
	snapchat = {'https://www.snapchat.com/add/'},
	sostronk = {'https://www.sostronk.com/tournament/'},
	['start-gg'] = {'https://start.gg/'},
	steam = {'https://steamcommunity.com/id/'},
	steamtv = {'https://steam.tv/'},
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
	weibo = {'https://weibo.com/'},
	yandexefir = {'https://yandex.ru/efir?stream_channel='},
	youtube = {'https://www.youtube.com/'},
	zhangyutv = {'http://www.zhangyu.tv/'},
	zhanqitv = {'https://www.zhanqi.tv/'},
}

PREFIXES = Table.merge(PREFIXES, CustomData.prefixes or {})

local SUFFIXES = {
	facebook = {
		'',
		stream = '/live',
	},
	iccup = {'.html'},
	['faceit-c'] = {'/'},
	['faceit-hub'] = {'/'},
	vk = {
		'',
		stream = '/live',
	},
}

SUFFIXES = Table.merge(SUFFIXES, CustomData.suffixes or {})

local ALIASES = {
	douyu = {'douyutv'},
	esl = {'eslgaming'},
	['facebook-gaming'] = {'fbgg'},
	home = {'website', 'web', 'site', 'url'},
	huyatv = {'huya'},
	letsplaylive = {'cybergamer'},
	rules = {'rulebook'},
	['start-gg'] = {'startgg', 'smashgg'},
	yandexefir = {'yandex'},
	zhanqitv = {'zhanqi'},
}

function Links.transform(links)
	local function iterateLinks(tbl, aliases)
		local index = 1
		local function getValue(keys)
			for _, key in ipairs(keys) do
				if tbl[key] then
					return tbl[key]
				end
			end
		end
		local function suffixAliases(alias)
			return alias .. index
		end

		return function()
			local keys = Array.map(aliases, suffixAliases)
			local value = getValue(keys)
			if index == 1 and not value then
				value = getValue(aliases)
			end
			index = index + 1
			if value then
				return (index - 1), value
			else
				return nil
			end
		end
	end

	local transformedLinks = {}
	for linkKey in pairs(PREFIXES) do
		local aliases = ALIASES[linkKey] or {}
		table.insert(aliases, 1, linkKey)

		for index, link in iterateLinks(links, aliases) do
			transformedLinks[linkKey .. (index == 1 and '' or index)] = link
		end
	end

	return transformedLinks
end

function Links.makeFullLink(platform, id, variant)
	if id == nil or id == '' then
		return ''
	end

	local prefixData = PREFIXES[platform]

	if not prefixData then
		return ''
	end

	local prefix = prefixData[variant] or prefixData[1]

	local suffixData = SUFFIXES[platform] or {}
	local suffix = suffixData[variant] or suffixData[1] or ''

	return prefix .. id .. suffix
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
