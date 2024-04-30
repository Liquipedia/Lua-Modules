---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

--- Core Widgets
Widgets.Builder = Lua.import('Module:Infobox/Widget/Builder')
Widgets.Customizable = Lua.import('Module:Infobox/Widget/Customizable')
Widgets.Error = Lua.import('Module:Infobox/Widget/Error')

--- Infobox Widgets
Widgets.Breakdown = Lua.import('Module:Infobox/Widget/Breakdown')
Widgets.Cell = Lua.import('Module:Infobox/Widget/Cell')
Widgets.Center = Lua.import('Module:Infobox/Widget/Center')
Widgets.Chronology = Lua.import('Module:Infobox/Widget/Chronology')
Widgets.Header = Lua.import('Module:Infobox/Widget/Header')
Widgets.Highlights = Lua.import('Module:Infobox/Widget/Highlights')
Widgets.Links = Lua.import('Module:Infobox/Widget/Links')
Widgets.Title = Lua.import('Module:Infobox/Widget/Title')

--- Table Widgets (div-table) (might be removed)
Widgets.Table = Lua.import('Module:Widget/Table')
Widgets.TableRow = Lua.import('Module:Widget/Table/Row')
Widgets.TableCell = Lua.import('Module:Widget/Table/Cell')

--- Table Widgets (html-table)
Widgets.TableNew = Lua.import('Module:Widget/Table/New')
Widgets.TableRowNew = Lua.import('Module:Widget/Table/Row/New')
Widgets.TableCellNew = Lua.import('Module:Widget/Table/Cell/New')

return Widgets
