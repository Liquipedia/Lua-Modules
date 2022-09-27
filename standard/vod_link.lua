---
-- @Liquipedia
-- wiki=commons
-- page=Module:VodLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')

local VodLink = {}

function VodLink.display(args)
	args = args or {}

	if Logic.readBool(args.novod) then
		return mw.html.create('span')
			:addClass('plainlinks')
			:attr('title', 'Help Liquipedia find this VOD')
			:wikitext('[[File:NoVod.png|link=]]')
	end

	local title
	local fileName = 'VOD Icon'
	if Logic.isNumeric(args.gamenum) then
		title = 'Watch Game ' .. args.gamenum
		if tonumber(args.gamenum) <= 11 then
			fileName = fileName .. args.gamenum
		end
	else
		title = 'Watch VOD'
	end
	title = args.htext or title
	fileName = fileName .. '.png'

	local link = args.vod or ''
	--question if we actually need the tlpd stuff
	--atm most wikis have it, but it seems very pointless except for sc/sc2
	if args.source == 'tlpd' or args.source == 'tlpd-kr' then
		link = 'https://www.tl.net/tlpd/sc2-korean/games/' .. link .. '/vod'
	elseif args.source == 'tlpd-int' then
		link = 'https://www.tl.net/tlpd/sc2-international/games/' .. link .. '/vod'
	end

	return mw.html.create('span')
		:addClass('plainlinks vodlink')
		:attr('title', title)
		:wikitext('[[File:' .. fileName .. '|link=' .. link .. ']]')
end

return Class.export(VodLink, {frameOnly = true})