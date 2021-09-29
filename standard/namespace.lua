---
-- @Liquipedia
-- wiki=commons
-- page=Module:Namespace
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Class = require('Module:Class')

local Namespace = {}

function Namespace.isMain()
	return mw.title.getCurrentTitle():inNamespace(0)
end

return Class.export(Namespace, {frameOnly = true})
