---
-- @Liquipedia
-- wiki=commons
-- page=Module:Medals
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Data = Lua.import('Module:Medals/Data', {loadData = true})

local Medals = {}

---@param args {medal: string|integer?, link: string?}?
---@return Html?
function Medals.display(args)
	args = args or {}
	local medalData = Medals.getData(args.medal)

	if not medalData then
		return
	end

	return mw.html.create('span')
		:attr('title', medalData.title)
		:wikitext('[[' .. medalData.file .. '|link=' .. (args.link or '') .. ']]')
end

---@param input string|integer?
---@return {title: string, file: string}?
function Medals.getData(input)
	return Data[tonumber(input) or input]
end

return Medals