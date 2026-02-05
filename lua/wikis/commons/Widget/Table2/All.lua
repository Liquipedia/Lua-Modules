---
-- @Liquipedia
-- page=Module:Widget/Table2/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.Table = Lua.import('Module:Widget/Table2/Table')
Widgets.TableHeader = Lua.import('Module:Widget/Table2/TableHeader')
Widgets.TableBody = Lua.import('Module:Widget/Table2/TableBody')
Widgets.TableFooter = Lua.import('Module:Widget/Table2/TableFooter')
Widgets.Row = Lua.import('Module:Widget/Table2/Row')
Widgets.CellHeader = Lua.import('Module:Widget/Table2/CellHeader')
Widgets.Cell = Lua.import('Module:Widget/Table2/Cell')
Widgets.Section = Lua.import('Module:Widget/Table2/Section')

return Widgets
