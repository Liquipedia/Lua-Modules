---
-- @author Vogan for Liquipedia
--

local Class = require('Module:Class')

local Links = {}

local _PREFIXES = {
    tlstream = "https://www.teamliquid.net/video/streams/",
    twitch = "https://www.twitch.tv/",
    stream = "",
    mildom = "https://www.mildom.com/",
    huomaotv = "http://www.huomao.com/",
    douyutv = "http://www.douyu.com/",
    pandatv = "http://www.panda.tv/",
    huyatv = "http://www.huya.com/",
    zhangyutv = "http://www.zhangyu.tv/",
    youtube = "http://www.youtube.com/",
    twitter = "https://twitter.com/",
    facebook = "http://facebook.com/",
    instagram = "http://www.instagram.com/",
    gplus = "http://plus.google.com/-plus",
    vk = "http://www.vk.com/",
    weibo = "http://weibo.com/",
    tlprofile = "https://www.teamliquid.net/forum/profile.php?user=",
    reddit = "https://www.reddit.com/user/",
    esl = "https://play.eslgaming.com/player/",
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
    fanclub = "",
    playlist = "",
    site = "",
    website = "",
    home = "",
    bracket = "",
    rules = "",
    aligulac = "https://aligulac.com/results/events/",
    booyah = "https://booyah.live/",
}

function Links.transform(links)
    return {
		home = links.website or links.web,
		azubu = links.azubu,
		discord = links.discord,
		facebook = links.facebook,
		instagram = links.instagram,
		reddit = links.reddit,
		snapchat = links.snapchat,
		steam = links.steam,
		tiktok = links.tiktok,
		twitch = links.twitch,
		twitter = links.twitter,
		weibo = links.weibo,
		vk = links.vk,
		youtube = links.youtube,
		aligulac = links.aligulac,
		rules = links.rules,
		booyah = links.booyah
	}
end

function Links.makeFullLink(platform, id)
    if id == nil or id == '' then
        return ''
    end

    if _PREFIXES[platform] == nil then
        return ''
    end

    return _PREFIXES[platform] .. id
end

return Class.export(Links, {frameOnly = true})
