---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.Breakdown = Lua.import('Module:Infobox/Widget/Breakdown')
Widgets.Builder = Lua.import('Module:Infobox/Widget/Builder')
Widgets.Cell = Lua.import('Module:Infobox/Widget/Cell')
Widgets.Center = Lua.import('Module:Infobox/Widget/Center')
Widgets.Chronology = Lua.import('Module:Infobox/Widget/Chronology')
Widgets.Customizable = Lua.import('Module:Infobox/Widget/Customizable')
Widgets.Error = Lua.import('Module:Infobox/Widget/Error')
Widgets.Header = Lua.import('Module:Infobox/Widget/Header')
Widgets.Links = Lua.import('Module:Infobox/Widget/Links')
Widgets.Title = Lua.import('Module:Infobox/Widget/Title')

Widgets.Table = Lua.import('Module:Widget/Table')
Widgets.TableRow = Lua.import('Module:Widget/Table/Row')
Widgets.TableCell = Lua.import('Module:Widget/Table/Cell')

return Widgets
