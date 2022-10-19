---
-- @Liquipedia
-- wiki=commons
-- page=Module:Namespace
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Table = require('Module:Table')

local Namespace = {}

function Namespace.isMain()
	return mw.title.getCurrentTitle():inNamespace(0) or mw.title.getCurrentTitle():inNamespace(829)
end

Namespace.getIdsByName = FnUtil.memoize(function()
	return Table.map(mw.site.namespaces, function(id, ns) return ns.name, id end)
end)

function Namespace.idFromName(name)
	return Namespace.getIdsByName()[name]
end

return Class.export(Namespace, {frameOnly = true})
