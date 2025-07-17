---
-- @Liquipedia
-- page=Module:VodLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local VodLink = {}

---@param args {vod: string, source: string?, gamenum: integer?}
---@return Html
function VodLink.display(args)
	args = args or {}
	local gameNumber = tonumber(args.gamenum)

	local title = VodLink.getTitle(gameNumber)
	local fileName = VodLink.getIcon(gameNumber)
	local link = args.vod or ''

	--question if we actually need the tlpd stuff
	--atm most wikis have it, but it seems very pointless except for sc1
	if args.source == 'tlpd' or args.source == 'tlpd-kr' then
		mw.ext.TeamLiquidIntegration.add_category('VodLink using tlpd')
		link = 'https://www.tl.net/tlpd/sc2-korean/games/' .. link .. '/vod'
	elseif args.source == 'tlpd-int' then
		mw.ext.TeamLiquidIntegration.add_category('VodLink using tlpd')
		link = 'https://www.tl.net/tlpd/sc2-international/games/' .. link .. '/vod'
	end

	return mw.html.create('span')
		:addClass('plainlinks vodlink')
		:attr('title', title)
		:wikitext('[[File:' .. fileName .. '|32px|link=' .. link .. ']]')
end

---@param gamenum integer?
---@return string
function VodLink.getTitle(gamenum)
	if gamenum then
		return 'Watch Game ' .. gamenum
	end
	return 'Watch VOD'
end

---@param gamenum integer?
---@return string
function VodLink.getIcon(gamenum)
	if gamenum and gamenum < 10 then
		return 'VOD Icon' .. gamenum .. '.png'
	end
	return 'VOD Icon.png'
end

return Class.export(VodLink, {frameOnly = true, exports = {'display'}})
