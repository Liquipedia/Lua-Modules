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
	if gamenum and gamenum > 0 and gamenum < 10 then
		return 'Vod-' .. gamenum .. '.svg'
	end
	return 'Vod.svg'
end

return Class.export(VodLink, {frameOnly = true, exports = {'display'}})
