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
Widgets.DataTable = Lua.import('Module:Widget/DataTable')

--- Base Html Widgets
Widgets.Div = Lua.import('Module:Widget/Div')
Widgets.Span = Lua.import('Module:Widget/Span')
Widgets.Table = Lua.import('Module:Widget/Table')
Widgets.Td = Lua.import('Module:Widget/Td')
Widgets.Th = Lua.import('Module:Widget/Th')
Widgets.Tr = Lua.import('Module:Widget/Tr')

return Widgets
