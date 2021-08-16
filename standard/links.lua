local Class = require('Module:Class')

local Links = {}

local _PREFIXES = {
    tlstream = "https://www.teamliquid.net/video/streams/",
    twitch = "https://www.twitch.tv/",
    twitch2 = "https://www.twitch.tv/",
    twitch3 = "https://www.twitch.tv/",
    twitch4 = "https://www.twitch.tv/",
    twitch5 = "https://www.twitch.tv/",
    stream = "",
    stream2 = "",
    mildom = "https://www.mildom.com/",
    huomaotv = "http://www.huomao.com/",
    douyu = "http://www.douyu.com/",
    pandatv = "http://www.panda.tv/",
    huyatv = "http://www.huya.com/",
    huyatv2 = "http://www.huya.com/",
    toornament = "https://www.toornament.com/tournaments/",
    toornament2 = "https://www.toornament.com/tournaments/",
    toornament3 = "https://www.toornament.com/tournaments/",
    battlefy = "https://www.battlefy.com/",
    battlefy2 = "https://www.battlefy.com/",
    battlefy3 = "https://www.battlefy.com/",
    zhangyutv = "http://www.zhangyu.tv/",
    youtube = "http://www.youtube.com/",
    youtube2 = "http://www.youtube.com/",
    youtube3 = "http://www.youtube.com/",
    youtube4 = "http://www.youtube.com/",
    youtube5 = "http://www.youtube.com/",
    twitter = "https://twitter.com/",
    twitter2 = "https://twitter.com/",
    facebook = "http://facebook.com/",
    facebook2 = "http://facebook.com/",
    instagram = "http://www.instagram.com/",
    instagram2 = "http://www.instagram.com/",
    gplus = "http://plus.google.com/-plus",
    vk = "http://www.vk.com/",
    weibo = "http://weibo.com/",
    tlprofile = "https://www.teamliquid.net/forum/profile.php?user=",
    reddit = "https://www.reddit.com/user/",
    esl = "",
    esl2 = "",
    esl3 = "",
    esl4 = "",
    esl5 = "",
    challonge = "",
    challonge2 = "",
    challonge3 = "",
    challonge4 = "",
    challonge5 = "",
    faceit = "https://www.faceit.com/en/players/",
    cybergamer = "https://au.cybergamer.com/profile/",
    steam = "https://steamcommunity.com/id/",
    steam2 = "https://steamcommunity.com/profiles/",
    snapchat = "https://www.snapchat.com/add/",
    sk = "http://sk-gaming.com/member/",
    discord = 'https://discord.gg/',
    tiktok = 'https://tiktok.com/@',
    telegram = "https://t.me/",
    trovo = "https://trovo.live/",
    trovo2 = "https://trovo.live/",
    fanclub = "",
    playlist = "",
    site = "",
    website = "",
    home = "",
    bracket = "",
    bracket2 = "",
    bracket3 = "",
    bracket4 = "",
    bracket5 = "",
    bracket6 = "",
    bracket7 = "",
    rules = "",
    aligulac = "https://aligulac.com/results/events/",
    booyah = "https://booyah.live/",
    loco = "https://loco.gg/streamers/",
    afreeca = "http://afreecatv.com/",
    afreeca2 = "http://afreecatv.com/",
    askfm = "https://ask.fm/",
    dlive = "https://www.dlive.tv/",
    matcherino = "https://matcherino.com/tournaments/",
    matcherinolink = "https://matcherino.com/t/",
    patreon = "https://www.patreon.com/",
    team = {
        aligulac = "http://aligulac.com/teams/",
        esl = "https://play.eslgaming.com/team/",
    },
    player = {
        aligulac = "http://aligulac.com/players/",
        esl = "https://play.eslgaming.com/player/",
    },
}

function Links.transform(links)
    return {
        home = links.website or links.web or links.site,
        home2 = links.website2 or links.web2 or links.site2,
        azubu = links.azubu,
        huyatv = links.huyatv,
        huyatv2 = links.huyatv2,
        discord = links.discord,
        facebook = links.facebook,
        facebook2 = links.facebook2,
        instagram = links.instagram,
        instagram2 = links.instagram2,
        reddit = links.reddit,
        snapchat = links.snapchat,
        steam = links.steam,
        tiktok = links.tiktok,
        twitch = links.twitch,
        twitch2 = links.twitch2,
        twitch3 = links.twitch3,
        twitch4 = links.twitch4,
        twitch5 = links.twitch5,
        twitter = links.twitter,
        twitter2 = links.twitter2,
        trovo = links.trovo,
        trovo2 = links.trovo2,
        afreeca = links.afreeca,
        afreeca2 = links.afreeca2,
        weibo = links.weibo,
        vk = links.vk,
        youtube = links.youtube,
        youtube2 = links.youtube2,
        youtube3 = links.youtube3,
        youtube4 = links.youtube4,
        youtube5 = links.youtube5,
        aligulac = links.aligulac,
        rules = links.rules,
        booyah = links.booyah,
        loco = links.loco,
        dlive = links.dlive,
        tlstream = links.tlstream,
        stream = links.stream,
        stream2 = links.stream2,
        douyu = links.douyu or links.douyutv,
        askfm = links.askfm,
        tlprofile = links.tlprofile,
        fanclub = links.fanclub,
        playlist = links.playlist,
        esl = links.eslgaming or links.esl,
        esl2 = links.eslgaming2 or links.esl2,
        esl3 = links.eslgaming3 or links.esl3,
        esl4 = links.eslgaming4 or links.esl4,
        esl5 = links.eslgaming5 or links.esl5,
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
        toornament = links.toornament,
        toornament2 = links.toornament2,
        toornament3 = links.toornament3,
        battlefy = links.battlefy,
        battlefy2 = links.battlefy2,
        battlefy3 = links.battlefy3,
        matcherino = links.matcherino,
        matcherinolink = links.matcherinolink,
        patreon = links.patreon,
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

return Class.export(Links, {frameOnly = true})
