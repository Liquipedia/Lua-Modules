---
-- @Liquipedia
-- wiki=commons
-- page=Module:Abbreviation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = {}

local Class = require('Module:Class')
local String = require('Module:StringUtils')

---@param title string?
---@param text string?
---@return string?
function Abbreviation.make(text, title)
	if String.isEmpty(title) or String.isEmpty(text) then
		return nil
	end
	return '<abbr title="' .. title .. '">' .. text .. '</abbr>'
end

return Class.export(Abbreviation)
