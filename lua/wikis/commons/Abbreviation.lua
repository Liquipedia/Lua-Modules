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
---@overload fun(text: {[1]: string|number, [2]: string|number}): string
---@overload fun(text: {[1]: ''|nil?, [2]: string|number}): nil
---@overload fun(text: {[1]: string|number, [2]: ''|nil?}): nil
---@overload fun(text: {title: string|number, text: string|number}): string
---@overload fun(text: {title: ''|nil?, text: string|number}): nil
---@overload fun(text: {title: string|number, text: ''|nil?}): nil
function Abbreviation.make(text, title)
	if type(text) == 'table' then
		title = text.title or text[2]
		text = text.text or text[1]
	end
	if Logic.isEmpty(title) or Logic.isEmpty(text) then
		return nil
	end
	return '<abbr title="' .. title .. '">' .. text .. '</abbr>'
end

return Class.export(Abbreviation)
