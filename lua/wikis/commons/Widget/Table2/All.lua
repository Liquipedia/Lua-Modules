---
-- @Liquipedia
-- page=Module:Widget/Table2/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Components = {}

local Lua = require('Module:Lua')

Components.Table = Lua.import('Module:Widget/Table2/Table')
Components.TableHeader = Lua.import('Module:Widget/Table2/TableHeader')
Components.TableBody = Lua.import('Module:Widget/Table2/TableBody')
Components.Row = Lua.import('Module:Widget/Table2/Row')
Components.CellHeader = Lua.import('Module:Widget/Table2/CellHeader')
Components.Cell = Lua.import('Module:Widget/Table2/Cell')

return Components
