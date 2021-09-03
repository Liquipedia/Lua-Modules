---
-- @Liquipedia
-- wiki=commons
-- page=Module:Links
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local Links = {}

local _PREFIXES = {
    afreeca = 'http://afreecatv.com/',
    aligulac = 'https://aligulac.com/results/events/',
    aoezone = 'https://aoezone.net/',
    askfm = 'https://ask.fm/',
    battlefy = 'https://www.battlefy.com/',
    booyah = 'https://booyah.live/',
    bracket = '',
    challonge = '',
    cybergamer = 'https://au.cybergamer.com/profile/',
    discord = 'https://discord.gg/',
    dlive = 'https://www.dlive.tv/',
    douyu = 'http://www.douyu.com/',
    esl = '',
    facebook = 'http://facebook.com/',
    faceit = 'https://www.faceit.com/en/players/',
    fanclub = '',
    gplus = 'http://plus.google.com/-plus',
    home = '',
    huomaotv = 'http://www.huomao.com/',
    huyatv = 'http://www.huya.com/',
    instagram = 'http://www.instagram.com/',
    loco = 'https://loco.gg/streamers/',
    matcherino = 'https://matcherino.com/tournaments/',
    matcherinolink = 'https://matcherino.com/t/',
    mildom = 'https://www.mildom.com/',
    octane = 'https://octane.gg/events/',
    patreon = 'https://www.patreon.com/',
    playlist = '',
    reddit = 'https://www.reddit.com/user/',
    rulebook = '',
    rules = '',
    site = '',
    sk = 'http://sk-gaming.com/member/',
    snapchat = 'https://www.snapchat.com/add/',
    steam = 'https://steamcommunity.com/id/',
    steamalternative = 'https://steamcommunity.com/profiles/',
    stream = '',
    telegram = 'https://t.me/',
    tiktok = 'https://tiktok.com/@',
    tlprofile = 'https://www.teamliquid.net/forum/profile.php?user=',
    tlstream = 'https://www.teamliquid.net/video/streams/',
    toornament = 'https://www.toornament.com/tournaments/',
    trovo = 'https://trovo.live/',
    twitch = 'https://www.twitch.tv/',
    twitter = 'https://twitter.com/',
    vk = 'http://www.vk.com/',
    website = '',
    weibo = 'http://weibo.com/',
    youtube = 'http://www.youtube.com/',
    zhangyutv = 'http://www.zhangyu.tv/',
    team = {
        aligulac = 'http://aligulac.com/teams/',
        esl = 'https://play.eslgaming.com/team/',
    },
    player = {
        aligulac = 'http://aligulac.com/players/',
        esl = 'https://play.eslgaming.com/player/',
    },
}

function Links.transform(links)
    return {
        afreeca = links.afreeca,
        afreeca2 = links.afreeca2,
        aligulac = links.aligulac,
        aoezone = links.aoezone,
        aoezone2 = links.aoezone2,
        aoezone3 = links.aoezone3,
        aoezone4 = links.aoezone4,
        aoezone5 = links.aoezone5,
        askfm = links.askfm,
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
        challonge = links.challonge,
        challonge2 = links.challonge2,
        challonge3 = links.challonge3,
        challonge4 = links.challonge4,
        challonge5 = links.challonge5,
        discord = links.discord,
        dlive = links.dlive,
        douyu = links.douyu,
        esl = links.eslgaming or links.esl,
        esl2 = links.eslgaming2 or links.esl2,
        esl3 = links.eslgaming3 or links.esl3,
        esl4 = links.eslgaming4 or links.esl4,
        esl5 = links.eslgaming5 or links.esl5,
        facebook = links.facebook,
        facebook2 = links.facebook2,
        fanclub = links.fanclub,
        home = links.website or links.web or links.site,
        home2 = links.website2 or links.web2 or links.site2,
        huyatv = links.huyatv,
        huyatv2 = links.huyatv2,
        instagram = links.instagram,
        instagram2 = links.instagram2,
        loco = links.loco,
        matcherino = links.matcherino,
        matcherinolink = links.matcherinolink,
        octane = links.octane,
        patreon = links.patreon,
        playlist = links.playlist,
        reddit = links.reddit,
        rules = links.rules or links.rulebook,
        snapchat = links.snapchat,
        steam = links.steam,
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
        vk = links.vk,
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

    if _PREFIXES[variant] then
        local out = _PREFIXES[variant][platform]
        if out then
            return out
        end
    end

    if _PREFIXES[platform] == nil then
        return ''
    end

    return _PREFIXES[platform] .. id
end

function Links.makeFullLinksForTableItems(links, variant)
	for key, item in pairs(links) do
		links[key] = Links.makeFullLink(self:_removeAppendedNumber(key), item, variant)
	end
	return links
end

--remove appended number
--needed because the link icons require e.g. 'esl' instead of 'esl2'
function Links:_removeAppendedNumber(key)
    return string.gsub(key, '%d$', '')
end

return Class.export(Links, {frameOnly = true})
