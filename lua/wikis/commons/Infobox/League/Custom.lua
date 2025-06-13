---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local League = Lua.import('Module:Infobox/League')

---@class CustomInfoboxLeague: InfoboxLeague
local CustomLeague = Class.new(League)

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	return league:createInfobox()
end

return CustomLeague
