---
-- @Liquipedia
-- wiki=commons
-- page=Module:Streams
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Flags = require('Module:Flags')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Streams = {}

-- possibly make usage of module:links if that is adjusted accordingly
local STREAM_DATA = {
	{platform = 'twitch', prefix = 'https://www.twitch.tv/'},
	{platform = 'youtube', prefix = 'https://www.youtube.com/', suffix = '/live'},
	{platform = 'mixer', prefix = 'https://www.mixer.com/', hasNoSpecialPage = true},
	{platform = 'facebook', prefix = 'https://facebook.com/', suffix = '/live'},
	{platform = 'vk', prefix = 'https://vk.com/', suffix = '/live', hasNoSpecialPage = true},
	{platform = 'douyu', prefix = 'https://www.douyu.com/'},
	{platform = 'huomao', prefix = 'https://www.huomao.com/', icon = 'huomaotv'},
	{platform = 'huya', prefix = 'https://www.huya.com/', icon = 'huyatv'},
	{platform = 'bilibili', prefix = 'https://live.bilibili.com/'},
	{platform = 'cc', prefix = 'https://cc.163.com/'},
	{platform = 'steamtv', prefix = 'https://steam.tv/', hasNoSpecialPage = true},
	{platform = 'garena', prefix = 'https://garena.live/', hasNoSpecialPage = true},
	{platform = 'zhanqi', prefix = 'https://www.zhanqi.tv/', icon = 'zhanqitv', hasNoSpecialPage = true},
	{platform = 'afreeca', prefix = 'https://play.afreecatv.com/', specialPage = 'afreecatv'},
	{platform = 'trovo', prefix = 'https://trovo.live/'},
	{platform = 'yandex', prefix = 'https://yandex.ru/efir?stream_channel=', icon = 'yandexefir', hasNoSpecialPage = true},
	{platform = 'mildom', prefix = 'https://www.mildom.com/'},
	{platform = 'esl', prefix = '', hasNoSpecialPage = true},
	{platform = 'openrec', prefix = 'https://www.openrec.tv/live/', hasNoSpecialPage = true},
	{platform = 'nimotv', prefix = 'https://www.nimo.tv/', specialPage = 'nimo'},
	{platform = 'booyah', prefix = 'https://booyah.live/'},
	{platform = 'loco', prefix = 'https://loco.gg/streamers/'},
	{platform = 'dlive', prefix = 'https://dlive.tv/', hasNoSpecialPage = true},
	{platform = 'stream', prefix = '', hasNoSpecialPage = true},
}

-- legacy alias
function Streams._create(args)
	return Streams.create(args)
end

function Streams.create(args)
	if type(args) ~= 'table' then
		return
	end

	local useSpecialPages = Logic.readBool(args.useSpecialPages)

	local tbl = mw.html.create('table')
		:addClass('wikitable')
		:css('text-align', 'center')
		:css('margin', '0')
		:css('margin-bottom', (args['margin-bottom'] or '1em'))

	if String.isNotEmpty(args.title) then
		tbl:node(mw.html.create('tr')
			:tag('th')
				:wikitext(args.title)
				:attr('colspan', 100)
		)
	end

	local languageRow = mw.html.create('tr')
	languageRow:tag('th'):wikitext('Language')

	local streamsRow = mw.html.create('tr')
	streamsRow:tag('th'):wikitext('Streams')


	for _, language, languageIndex in Table.iter.pairsByPrefix(args, 'lang') do
		languageRow:tag('td')
			:wikitext(Flags.Icon{flag = language, shouldLink = false})

		local langStreams = {}
		for _, streamData in ipairs(STREAM_DATA) do
			local platform = streamData.platform

			args[1 .. platform .. languageIndex] = args[platform .. languageIndex] or args[1 .. platform .. languageIndex]
			if platform == 'youtube' then
				args[1 .. 'ytmultiple' .. languageIndex] = args['ytmultiple' .. languageIndex]
					or args[1 .. 'ytmultiple' .. languageIndex]
			end

			local streamIndex = 1
			while(String.isNotEmpty(args[streamIndex .. platform .. languageIndex])) do
				local streamDisplay
				if not useSpecialPages or streamData.hasNoSpecialPage then
					local suffix = platform == 'youtube'
						and String.isNotEmpty(args[streamIndex .. 'ytmultiple' .. languageIndex]) and '/videos?view=2&live_view=501'
						or streamData.suffix or ''

					streamDisplay = '[' .. streamData.prefix .. args[streamIndex .. platform .. languageIndex] .. suffix
						.. ' <i class="lp-icon lp-' .. (streamData.icon or platform) .. '" style="margin-bottom:3.0px;"></i>]'
				else
					streamDisplay = '[[Special:StreamPage/' .. platform .. args[streamIndex .. platform .. languageIndex] .. '|'
						.. '<i class="lp-icon lp-' .. (streamData.icon or platform) .. '" style="margin-bottom:3.0px;"></i>]]'
				end

				table.insert(langStreams, streamDisplay)

				streamIndex = streamIndex + 1
			end
		end

		streamsRow:tag('td')
			:css('vertical-align', 'top')
			:wikitext(table.concat(langStreams, '<br>'))
	end

	tbl
		:node(languageRow)
		:node(streamsRow)

	return mw.html.create('div')
		:addClass('table-responsive')
		:node(tbl)
end

return Class.export(Streams)
