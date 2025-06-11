---
-- @Liquipedia
-- page=Module:Abbreviation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = {}

local Class = require('Module:Class')
local Logic = require('Module:Logic')


---@param args {text: string, title: string}
---@return string
---@overload fun(args: {text: nil?, title: any}): nil
---@overload fun(args: {text: any, title: nil?}): nil
---@overload fun(): nil
function Abbreviation.make(args)
	args = args or {}
	local text = args.text
	local title = args.title
	if Logic.isEmpty(title) or Logic.isEmpty(text) then
		return nil
	end
	return '<abbr title="' .. title .. '">' .. text .. '</abbr>'
end

return Class.export(Abbreviation, {exports = {'make'}})
