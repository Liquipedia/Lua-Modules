---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

--- Core Widgets
Widgets.Builder = Lua.import('Module:Widget/Builder')
Widgets.Customizable = Lua.import('Module:Widget/Customizable')

--- Infobox Widgets
Widgets.Breakdown = Lua.import('Module:Widget/Infobox/Breakdown')
Widgets.Cell = Lua.import('Module:Widget/Infobox/Cell')
Widgets.Center = Lua.import('Module:Widget/Infobox/Center')
Widgets.Chronology = Lua.import('Module:Widget/Infobox/Chronology')
Widgets.Header = Lua.import('Module:Widget/Infobox/Header')
Widgets.Highlights = Lua.import('Module:Widget/Infobox/Highlights')
Widgets.Links = Lua.import('Module:Widget/Infobox/Links')
Widgets.Title = Lua.import('Module:Widget/Infobox/Title')

--- Generic Widgets
Widgets.Div = Lua.import('Module:Widget/Div')

--- Table Widgets (div-table) (might be removed)
Widgets.Table = Lua.import('Module:Widget/Table')
Widgets.TableRow = Lua.import('Module:Widget/Table/Row')
Widgets.TableCell = Lua.import('Module:Widget/Table/Cell')

--- Table Widgets (html-table)
Widgets.TableNew = Lua.import('Module:Widget/Table/New')
Widgets.TableRowNew = Lua.import('Module:Widget/Table/Row/New')
Widgets.TableCellNew = Lua.import('Module:Widget/Table/Cell/New')

return Widgets
