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

---@param text string|number
---@param title string|number
---@return string
---@overload fun(text: string|number, title: nil?):nil
---@overload fun(text: string|number, title: ''):nil
---@overload fun(text: nil?, title: string|number):nil
---@overload fun(text: '', title: string|number):nil
---@overload fun(text: nil?, title: nil?):nil
---@overload fun(text: '', title: ''):nil
function Abbreviation.make(text, title)
	if Logic.isEmpty(title) or Logic.isEmpty(text) then
		return nil
	end
	return '<abbr title="' .. title .. '">' .. text .. '</abbr>'
end

return Class.export(Abbreviation)
