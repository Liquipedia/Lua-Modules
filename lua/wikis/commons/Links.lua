---
-- @Liquipedia
-- page=Module:Links
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local CustomData = Lua.requireIfExists('Module:Links/CustomData', {loadData = true}) or {}

local Links = {}

local PREFIXES = {
	['365chess'] = {
		'https://www.365chess.com/tournaments/',
		player = 'https://www.365chess.com/players/',
		match = 'https://www.365chess.com/game.php?gid=',
	},
	['5ewin'] = {
		'https://arena.5eplay.com/tournament/',
		player = 'https://arena.5eplay.com/data/player/',
		team = 'https://arena.5eplay.com/team/',
	},
	abiosgaming = {'https://abiosgaming.com/tournaments/'},
	apexlegendsstatus = {'https://apexlegendsstatus.com/profile/uid/PC/'},
	['apple-podcasts'] = {'https://podcasts.apple.com/'},
	afreeca = {
		'http://afreecatv.com/',
		stream = 'https://play.afreecatv.com/',
	},
	aoezone = {
		'https://aoezone.net/',
		player = 'https://aoezone.net/members/'
	},
	['ask-fm'] = {'https://ask.fm/'},
	b5csgo = {
		'',
		player = 'https://www.b5csgo.com/personalCenter/',
		team = 'https://www.b5csgo.com/clan/'
	},
	ballchasing = {
		match = 'https://ballchasing.com/group/',
	},
	battlefy = {'https://www.battlefy.com/'},
	bilibili = {
		'https://space.bilibili.com/',
		stream = 'https://live.bilibili.com/',
	},
	['bilibili-stream'] = {'https://live.bilibili.com/'},
	blasttv = {
		'https://blast.tv/',
		match = 'https://blast.tv/',
	},
	bluesky = {'https://bsky.app/profile/'},
	booyah = {'https://booyah.live/'},
	bracket = {''},
	breakingpoint = {match = 'https://www.breakingpoint.gg/match/'},
	cc = {'https://cc.163.com/'},
	cdl = {match = 'https://callofdutyleague.com/en-us/match/'},
	challengermode = {
		'https://www.challengermode.com/tournaments/',
		player = 'https://www.challengermode.com/users/',
		team = 'https://www.challengermode.com/teams/',
		match = 'https://www.challengermode.com/games/',
	},
	challonge = {
		'',
		player = 'https://challonge.com/users/',
	},
	chesscom = {
		'https://www.chess.com/',
		player = 'https://www.chess.com/member/',
		match = 'https://www.chess.com/games/view/',
	},
	chessgames = {
		'https://www.chessgames.com/perl/chess.pl?tid=',
		player = 'https://www.chessgames.com/perl/chessplayer?pid=',
		match = 'https://www.chessgames.com/perl/chessgame?gid=',
	},
	chessresults = {'https://chess-results.com/'},
	chzzk = {'https://chzzk.naver.com/live/'},
	civdraft = {match = 'https://aoe2cm.net/draft/'},
	cntft = {'https://lol.qq.com/tft/#/masterDetail/'},
	corestrike = {'https://corestrike.gg/lookup/'},
	cfs = {'https://www.crossfirestars.com/'},
	datdota = {
		'https://www.datdota.com/leagues/',
		player = 'https://www.datdota.com/players/',
		team = 'https://www.datdota.com/teams/'
	},
	daumcafe = {'http://cafe.daum.net/'},
	dbstats = {match = 'https://quakelife.ru/diabotical/stats/matches/?matches='},
	discord = {'https://discord.gg/'},
	dlive = {'https://www.dlive.tv/'},
	dotabuff = {
		'https://www.dotabuff.com/esports/leagues/',
		player = 'https://www.dotabuff.com/esports/players/',
		team = 'https://www.dotabuff.com/esports/teams/'
	},
	douyin = {'https://live.douyin.com/'},
	douyin_page = {'https://v.douyin.com/'},
	douyu = {'https://www.douyu.com/'},
	ebattle = {match = 'https://www.ebattle.gg/turnier/match/'},
	esea = {
		'https://play.esea.net/events/',
		player = 'https://play.esea.net/users/',
		team = 'https://play.esea.net/teams/',
		match = 'https://play.esea.net/match/',
	},
	['esea-d'] = {'https://play.esea.net/league/standings?divisionId='},
	esl = {
		'',
		team = 'https://play.eslgaming.com/team/',
		player = 'https://play.eslgaming.com/player/',
		match = 'https://play.eslgaming.com/match/',
	},
	esplay = {'https://esplay.com/tournament/'},
	esportal = {'https://esportal.com/tournament/'},
	etf2l = {
		'',
		team = 'https://etf2l.org/teams/',
		player = 'https://etf2l.org/forum/user/',
		match = 'https://etf2l.org/matches/',
	},
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
	fanclub = {''},
	fide = {
		'https://ratings.fide.com/tournament_information.phtml?event=',
		player = 'https://ratings.fide.com/profile/',
	},
	geoguessr = {'https://www.geoguessr.com/'},
	gol = {match = 'https://gol.gg/game/stats/'},
	gosugamers = {''},
	gplus = {'http://plus.google.com/-plus'},
	halodatahive = {
		'https://halodatahive.com/Tournament/Detail/',
		team = 'https://halodatahive.com/Team/Detail/',
		player = 'https://halodatahive.com/Player/Detail/',
		match = 'https://halodatahive.com/Series/Summary/',
	},
	home = {''},
	haojiao = {
		'https://web.haojiao.cc/wiki/tour/t2Ud5pOQlscKLbRC/',
		team = 'https://web.haojiao.cc/wiki/team/t2Ud5pOQlscKLbRC/',
		player = 'https://web.haojiao.cc/wiki/player/t2Ud5pOQlscKLbRC/',
	},
	huyatv = {'https://www.huya.com/'},
	iccup = {'http://www.iccup.com/starcraft/gamingprofile/'},
	instagram = {'https://www.instagram.com/'},
	interview = {'', match = ''},
	jcg = {match = 'https://web.archive.org/web/ow.j-cg.com/compe/view/match/'},
	kick = {'https://www.kick.com/'},
	kuaishou = {'https://live.kuaishou.com/u/'},
	['letsplaylive-old'] = {
		'https://old.letsplay.live/event/',
		team = 'https://old.letsplay.live/team/',
		player = 'https://old.letsplay.live/profile/',
	},
	letsplaylive = {
		'https://gg.letsplay.live/tournament/',
		team = 'https://gg.letsplay.live/view-team/',
		player = 'https://gg.letsplay.live/profile/view-stats/',
		match = 'https://old.letsplay.live/match/',
	},
	lichess = {
		'https://lichess.org/broadcast/',
		player = 'https://lichess.org/@/',
		match = 'https://lichess.org/'
	},
	linkedin = {
		team = 'https://www.linkedin.com/company/',
		player = 'https://www.linkedin.com/in/',
	},
	loco = {'https://loco.gg/streamers/'},
	lolchess = {'https://lolchess.gg/profile/'},
	lrthread = {'', match = ''},
	mapdraft = {match = 'https://aoe2cm.net/draft/'},
	matcherino = {'https://matcherino.com/tournaments/'},
	matcherinolink = {'https://matcherino.com/t/'},
	mildom = {'https://www.mildom.com/'},
	mplink = {match = 'https://osu.ppy.sh/community/matches/'}, -- Should this key be renamed?
	niconico = {'https://www.nicovideo.jp/'},
	nimotv = {'https://www.nimo.tv/'},
	['nwc3l'] = {
		'',
		team = 'https://nwc3l.com/team/',
		player = 'https://nwc3l.com/profile/',
	},
	openrec = {'https://www.openrec.tv/live/'},
	opl = {
		match = 'https://www.opleague.eu/match/'
	},
	osu = {
		'https://osu.ppy.sh/',
		player = 'https://osu.ppy.sh/users/',
	},
	overgg = {match = 'https://www.over.gg/'},
	owl = {
		match = 'https://web.archive.org/web/overwatchleague.com/en-us/match/',
	},
	ozf = {match = 'https://warzone.ozfortress.com/matches/'},
	patreon = {'https://www.patreon.com/'},
	pf = {match = 'https://www.plusforward.net/quake/post/'},
	playlist = {''},
	preview = {'', match = ''},
	qrindr = {match = 'https://qrindr.com/match/'},
	quakehistory = {match = 'http://www.quakehistory.com/en/matches/'},
	r6esports = {
		match = 'https://www.ubisoft.com/en-us/esports/rainbow-six/siege/match/',
	},
	reddit = {
		'https://www.reddit.com/user/',
		match = 'https://redd.it/',
	},
	replay = {''},
	recap = {'', match = ''},
	review = {'', match = ''},
	rgl = {
		'https://rgl.gg/Public/LeagueTable?s=',
		team = 'https://rgl.gg/Public/Team?t=',
		player = 'https://rgl.gg/Public/PlayerProfile?p=',
		match = 'https://rgl.gg/Public/Match.aspx?m=',
	},
	rooter = {'https://rooter.gg/'},
	royaleapi = {
		'https://royaleapi.com/player/',
		match = 'https://royaleapi.com/'
	},
	rules = {''},
	shift = {
		'https://www.shiftrle.gg/events/',
		match = 'https://www.shiftrle.gg/matches/',
	},
	siegegg = {
		'https://siege.gg/competitions/',
		team = 'https://siege.gg/teams/',
		player = 'https://siege.gg/players/',
		match = 'https://siege.gg/matches/',
	},
	sk = {'https://sk-gaming.com/member/'},
	smashboards = {'https://smashboards.com/'},
	snapchat = {'https://www.snapchat.com/add/'},
	soop = {'https://www.sooplive.com/'},
	sostronk = {'https://www.sostronk.com/tournament/'},
	['start-gg'] = {
		'https://start.gg/',
		player = 'https://start.gg/user/',
	},
	steam = {'https://steamcommunity.com/id/'},
	steamtv = {'https://steam.tv/'},
	strikr = {'https://strikr.pro/pilot/'},
	privsteam = {'https://steamcommunity.com/groups/'},
	pubsteam = {'https://steamcommunity.com/groups/'},
	smiteesports = {match = 'https://www.smiteesports.com/matches/'},
	spotify = {'https://open.spotify.com/'},
	steamalternative = {'https://steamcommunity.com/profiles/'},
	stats = {'', match = ''},
	stratz = {
		'https://stratz.com/leagues/',
		player = 'https://stratz.com/players/',
		team = 'https://stratz.com/teams/'
	},
	stream = {''},
	telegram = {'https://t.me/'},
	tespa = {match = 'https://web.archive.org/web/compete.tespa.org/tournament/'},
	tftv = {
		'https://www.teamfortress.tv/',
		player = 'https://www.teamfortress.tv/user/',
		match = 'http://tf.gg/',
	},
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
	tonamel = {'https://tonamel.com/competition/'},
	toornament = {'https://play.toornament.com/tournaments/'},
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
		player = 'https://www.vlr.gg/player/',
		match = 'https://vlr.gg/',
	},
	vod = {''},
	weibo = {'https://weibo.com/'},
	wl = {match = 'https://www.winstonslab.com/matches/match.php?id='},
	yandexefir = {'https://yandex.ru/efir?stream_channel='},
	youtube = {'https://www.youtube.com/'},
	zhangyutv = {'http://www.zhangyu.tv/'},
	zhanqitv = {'https://www.zhanqi.tv/'},
}

PREFIXES = Table.merge(PREFIXES, CustomData.prefixes or {})

local SUFFIXES = {
	chessresults = {'.aspx'},
	cntft = {'/1'},
	esportal = {'/event/info'},
	facebook = {
		'',
		stream = '/live',
	},
	gol = {match = '/page-game/'},
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
	['ask-fm'] = {'afk.fm', 'askfm'},
	douyu = {'douyutv'},
	esl = {'eslgaming'},
	['facebook-gaming'] = {'fbgg'},
	home = {'website', 'web', 'site', 'url'},
	huyatv = {'huya'},
	['letsplaylive-old'] = {'cybergamer'},
	replay = {'replays'},
	rules = {'rulebook'},
	['start-gg'] = {'startgg', 'smashgg'},
	yandexefir = {'yandex'},
	zhanqitv = {'zhanqi'},
}

local ICON_KEYS_TO_RENAME = {
	['bilibili-stream'] = 'bilibili',
	daumcafe = 'cafe-daum',
	blasttv = 'blast',
	['esea-d'] = 'esea-league',
	['faceit-c'] = 'faceit',
	['faceit-c2'] = 'faceit',
	['faceit-l'] = 'faceit',
	['faceit-hub'] = 'faceit',
	['faceit-org'] = 'faceit',
	matcherinolink = 'matcherino',
	playlist = 'music',
	privsteam = 'steam',
	pubsteam = 'steam',
	steamalternative = 'steam',
	tlpdint = 'tlpd',
	tlpdkr = 'tlpd-wol-korea',
	tlpdsospa = 'tlpd-sospa',
	douyin_page = 'douyin',
}

local MATCH_ICONS = {
	['365chess'] = {
		icon = 'File:365chess_allmode.png',
		iconDark = 'File:365chess_allmode.png',
		text = '365Chess matchpage'
	},
	ballchasing = {
		icon = 'File:Ballchasing icon.png',
		text = 'Ballchasing replays'
	},
	blasttv = {
		icon = 'File:BLAST icon allmode.png',
		text = 'BLAST.tv matchpage'
	},
	breakingpoint = {
		icon = 'File:Breaking Point GG icon lightmode.png',
		iconDark = 'File:Breaking Point GG icon darkmode.png',
		text = 'Breaking Point matchpage'
	},
	cdl = {
		icon = 'File:Call of Duty League lightmode.png',
		iconDark = 'File:Call of Duty League darkmode.png',
		text = 'Call of Duty League matchpage'
	},
	challengermode = {
		icon = 'File:Challengermode icon.png',
		text = 'Match page on Challengermode'
	},
	chesscom = {
		icon = 'File:ChessCom_allmode.png',
		iconDark = 'File:ChessCom_allmode.png',
		text = 'Chess.com matchpage'
	},
	chessgames = {
		icon = 'File:Chessgames_allmode.png',
		iconDark = 'File:Chessgames_allmode.png',
		text = 'Chessgames matchpage'
	},
	civdraft = {
		text = 'Civ Draft',
		icon = 'File:Civ Draft Icon.png'
	},
	datdota = {
		icon = 'File:DatDota-icon.png',
		text = 'datDota'
	},
	dbstats = {
		icon = 'File:Diabotical icon.png',
		text = 'QuakeLife matchpage'
	},
	dotabuff = {
		icon = 'File:DOTABUFF-icon.png',
		text = 'DOTABUFF'
	},
	ebattle = {
		icon = 'File:Ebattle Series allmode.png',
		text = 'Match page on ebattle'
	},
	esl = {
		icon = 'File:ESL_2019_icon_lightmode.png',
		iconDark = 'File:ESL_2019_icon_darkmode.png',
		text = 'Match page on ESL'
	},
	esea = {
		icon = 'File:ESEA icon allmode.png',
		text = 'ESEA Match Page'
	},
	etf2l = {
		icon = 'File:ETF2L.png',
		text = 'ETF2L Match Page'
	},
	faceit = {
		icon = 'File:FACEIT icon allmode.png',
		text = 'FACEIT match room'
	},
	gol = {
		icon = 'File:Gol.gg allmode.png',
		text = 'GolGG Match Report',
	},
	halodatahive = {
		icon = 'File:Halo Data Hive allmode.png',
		text = 'Match page on Halo Data Hive'
	},
	headtohead = {
		icon = 'File:Match Info Stats.png',
		text = 'Head-to-head statistics'
	},
	interview = {
		icon = 'File:Interview32.png',
		text = 'Interview'
	},
	jcg = {
		icon = 'File:JCG-BMS icon.png',
		text = 'JCG matchpage'
	},
	lichess = {
		icon = 'File:Lichess_lightmode.png',
		iconDark = 'File:Lichess_darkmode.png',
		text = 'Game page on Lichess'
	},
	logstf = {
		icon = 'File:Logstf_icon.png',
		text = 'logs.tf Match Page '
	},
	logstfgold = {
		icon = 'File:Logstf_gold_icon.png',
		text = 'logs.tf Match Page (Golden Cap) '
	},
	lpl = {
		icon = 'File:LPL_Logo_lightmode.png',
		iconDark = 'File:LPL_Logo_darkmode.png',
		text = 'Match page on LPL Play'
	},
	lrthread = {
		icon = 'File:LiveReport32.png',
		text = 'Live Report Thread'
	},
	mapdraft = {
		text = 'Map Draft',
		icon = 'File:Map Draft Icon.png'
	},
	mplink = {
		icon = 'File:Osu single color allmode.png',
		text = 'Match Data'
	},
	opl = {
		icon = 'File:OPL Icon 2023 allmode.png',
		text = 'OPL Match Page'
	},
	overgg = {
		icon = 'File:overgg icon.png',
		text = 'over.gg matchpage'
	},
	owl = {
		icon = 'File:Overwatch League 2023 allmode.png',
		text = 'Overwatch League matchpage'
	},
	ozf = {
		icon = 'File:ozfortress-icon.png',
		text = 'ozfortress Match Page'
	},
	pf = {
		icon = 'File:Plus Forward icon.png',
		text = 'Plus Forward matchpage'
	},
	preview = {
		icon = 'File:Preview Icon32.png',
		text = 'Preview'
	},
	qrindr = {
		icon = 'File:Quake Champions icon.png',
		text = 'Qrindr matchpage'
	},
	r6esports = {
		icon = 'File:Rainbow 6 Esports 2023 lightmode.png',
		iconDark = 'File:Rainbow 6 Esports 2023 darkmode.png',
		text = 'R6 Esports Match Page'
	},
	recap = {
		icon = 'File:Reviews32.png',
		text = 'Recap'
	},
	reddit = {
		icon = 'File:Reddit-icon.png',
		text = 'Reddit Thread',
	},
	review = {
		icon = 'File:Reviews32.png',
		text = 'Review'
	},
	rgl = {
		icon = 'File:RGL_Logo.png',
		text = 'RGL Match Page'
	},
	royaleapi = {
		icon = 'File:RoyaleAPI_allmode.png',
		text = 'RoyaleAPI Match Page'
	},
	shift = {
		icon = 'File:ShiftRLE icon.png',
		text = 'ShiftRLE matchpage'
	},
	siegegg = {
		icon = 'File:SiegeGG icon.png',
		text = 'SiegeGG Match Page'
	},
	smiteesports = {
		icon = 'File:SMITE default lightmode.png',
		iconDark = 'File:SMITE default darkmode.png',
		text = 'Smite Esports Match Page'
	},
	stats = {
		icon = 'File:Match_Info_Stats.png',
		text = 'Match Statistics'
	},
	stratz = {
		icon = 'File:STRATZ_icon_lightmode.svg',
		iconDark = 'File:STRATZ_icon_darkmode.svg',
		text = 'STRATZ'
	},
	tespa = {
		icon = 'File:Tespa icon.png',
		text = 'Tespa matchpage'
	},
	tftv = {
		icon = 'File:Teamfortress.tv.png',
		text = 'TFTV Match Page'
	},
	vlr = {
		icon = 'File:VLR icon.png',
		text = 'Matchpage and Stats on VLR'
	},
	wl = {
		icon = 'File:Winstons Lab-icon.png',
		text = 'Winstons Lab matchpage'
	},
}

MATCH_ICONS = Table.merge(MATCH_ICONS, CustomData.matchIcons or {})

---@param links {[string]: string}
---@return {[string]: string}
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

---@param args {platform: string, id: string?, variant: string?, fallbackToBase: boolean?}
---@return string
function Links.makeFullLink(args)
	local id = args.id
	local variant = args.variant
	local fallbackToBase = args.fallbackToBase
	local platform = args.platform
	if id == nil or id == '' then
		return ''
	end

	local prefixData = PREFIXES[platform]

	if not prefixData then
		return ''
	end

	local suffixData = SUFFIXES[platform] or {}

	local prefix = prefixData[variant]
	local suffix = suffixData[variant]
	if fallbackToBase ~= false then
		prefix = prefix or prefixData[1]
		suffix = suffix or suffixData[1]
	end

	if not prefix then
		return ''
	end

	return prefix .. id .. (suffix or '')
end

---@param links {[string]: string}
---@param variant string?
---@param fallbackToBase boolean? #defaults to true
---@return {[string]: string}
function Links.makeFullLinksForTableItems(links, variant, fallbackToBase)
	return Table.map(links, function(key, item)
		return key, Links.makeFullLink{
			platform = Links.removeAppendedNumber(key),
			id = item,
			variant = variant,
			fallbackToBase = fallbackToBase,
		}
	end)
end

--remove appended number
--needed because the link icons Lua.import e.g. 'esl' instead of 'esl2'
---@param key string
---@return string
function Links.removeAppendedNumber(key)
	return (string.gsub(key, '%d$', ''))
end

---Builds the icon for a given link
---@param key string
---@param size number?
---@return string
function Links.makeIcon(key, size)
	return '<i class="lp-icon lp-' .. (ICON_KEYS_TO_RENAME[key] or key)
		.. (size and (' lp-icon-' .. size) or '') .. '></i>'
end

---Fetches Icon Data for a given key
---@param key string
---@return {icon: string, text: string, iconDark: string?}?
function Links.getMatchIconData(key)
	return MATCH_ICONS[Links.removeAppendedNumber(key)]
end

return Class.export(Links, {frameOnly = true, exports = {'makeFullLink'}})
