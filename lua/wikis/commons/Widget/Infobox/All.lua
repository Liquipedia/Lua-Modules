---
-- @Liquipedia
-- page=Module:Widget/Infobox/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.Breakdown = Lua.import('Module:Widget/Infobox/Breakdown')
Widgets.Cell = Lua.import('Module:Widget/Infobox/Cell')
Widgets.Center = Lua.import('Module:Widget/Infobox/Center')
Widgets.Chronology = Lua.import('Module:Widget/Infobox/Chronology')
Widgets.Header = Lua.import('Module:Widget/Infobox/Header')
Widgets.Highlights = Lua.import('Module:Widget/Infobox/Highlights')
Widgets.Links = Lua.import('Module:Widget/Infobox/Links')
Widgets.Table = Lua.import('Module:Widget/Infobox/Table')
Widgets.Title = Lua.import('Module:Widget/Infobox/Title')

return Widgets
