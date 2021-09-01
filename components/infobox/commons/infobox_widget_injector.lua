---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Injector
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local Injector = Class.new()

function Injector:parse(id, widgets)
	return error('You need to implement the parse function in your widget injector!')
end

function Injector:addCustomCells(widgets)
	return {}
end

return Injector

