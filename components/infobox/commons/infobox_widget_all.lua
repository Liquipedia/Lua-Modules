---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.Breakdown = Lua.import('Module:Infobox/Widget/Breakdown', {requireDevIfEnabled = true})
Widgets.Builder = Lua.import('Module:Infobox/Widget/Builder', {requireDevIfEnabled = true})
Widgets.Cell = Lua.import('Module:Infobox/Widget/Cell', {requireDevIfEnabled = true})
Widgets.Center = Lua.import('Module:Infobox/Widget/Center', {requireDevIfEnabled = true})
Widgets.Chronology = Lua.import('Module:Infobox/Widget/Chronology', {requireDevIfEnabled = true})
Widgets.Customizable = Lua.import('Module:Infobox/Widget/Customizable', {requireDevIfEnabled = true})
Widgets.Error = Lua.import('Module:Infobox/Widget/Error', {requireDevIfEnabled = true})
Widgets.Header = Lua.import('Module:Infobox/Widget/Header', {requireDevIfEnabled = true})
Widgets.Links = Lua.import('Module:Infobox/Widget/Links', {requireDevIfEnabled = true})
Widgets.Title = Lua.import('Module:Infobox/Widget/Title', {requireDevIfEnabled = true})

return Widgets
