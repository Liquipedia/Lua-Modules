---
-- @Liquipedia
-- wiki=commons
-- page=Module:Medals
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Data = Lua.import('Module:MedalDisplay/Data', {loadData = true})

local MedalDisplay = {}

---@param args {medal: string|integer?, link: string?}?
---@return Html?
function MedalDisplay.display(args)
	args = args or {}
	local medalData = MedalDisplay.getData(args.medal)

	if not medalData then
		return
	end

	return mw.html.create('span')
		:attr('title', medalData.title)
		:wikitext('[[' .. medalData.file .. '|link=' .. (args.link or '') .. ']]')
end

---@param input string|integer?
---@return {title: string, file: string}?
function MedalDisplay.getData(input)
	return Data.medals[MedalDisplay._toIdentifier(input)]
end

---@param input string|integer?
---@return string|number?
function MedalDisplay._toIdentifier(input)
	return tonumber(input) or Data.aliases[input] or input
end

return MedalDisplay