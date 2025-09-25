---
-- @Liquipedia
-- page=Module:Medals
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Data = Lua.import('Module:Medals/Data', {loadData = true})
local Image = Lua.import('Module:Image')

local Medals = {}

---@param args {medal: string|integer?, link: string?}?
---@return Html?
function Medals.display(args)
	args = args or {}
	local medalData = Medals.getData(args.medal)

	if not medalData then
		return
	end

	local medalImage = Image.display(
		medalData.file,
		nil,
		{link = args.link or '', alt = medalData.title, size = '24x24px'}
	)

	return mw.html.create('span'):attr('title', medalData.title):wikitext(medalImage)
end

---@param input string|integer?
---@return {title: string, file: string}?
function Medals.getData(input)
	return Data[tonumber(input) or input]
end

return Medals
