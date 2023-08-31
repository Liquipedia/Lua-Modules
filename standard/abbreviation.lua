---
-- @Liquipedia
-- wiki=commons
-- page=Module:Abbreviation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = {}

local Class = require('Module:Class')
local Logic = require('Module:Logic')

---@param title string|number|nil
---@param text string|number|nil
---@return string?
function Abbreviation.make(text, title)
	if Logic.isEmpty(title) or Logic.isEmpty(text) then
		return nil
	end
	return '<abbr title="' .. title .. '">' .. text .. '</abbr>'
end

return Class.export(Abbreviation)
