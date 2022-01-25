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

function Abbreviation.make(title, text)
	if String.isEmpty(title) or String.isEmpty(text) then
		return nil
	end
	return '<abbr title="' .. title .. '>' .. text .. '</abbr>'
end

return Class.export(Abbreviation)
