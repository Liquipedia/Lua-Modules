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

--- Table Widgets (div-table) (will be removed)
Widgets.TableOld = Lua.import('Module:Widget/Table/Old')
Widgets.TableRow = Lua.import('Module:Widget/Table/Row')
Widgets.TableCell = Lua.import('Module:Widget/Table/Cell')

--- Data Table Widgets (html-table)
Widgets.DataTable = Lua.import('Module:Widget/Basic/DataTable')

--- Base Html Widgets
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
Widgets.Div = HtmlWidgets.Div
Widgets.Span = HtmlWidgets.Span
Widgets.Table = HtmlWidgets.Table
Widgets.Td = HtmlWidgets.Td
Widgets.Th = HtmlWidgets.Th
Widgets.Tr = HtmlWidgets.Tr

return Widgets
