---
-- @Liquipedia
-- page=Module:Components/Table2/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Components = {}

local Lua = require('Module:Lua')

Components.Table = Lua.import('Module:Components/Table2/Table')
Components.TableHeader = Lua.import('Module:Components/Table2/TableHeader')
Components.TableBody = Lua.import('Module:Components/Table2/TableBody')
Components.Row = Lua.import('Module:Components/Table2/Row')
Components.CellHeader = Lua.import('Module:Components/Table2/CellHeader')
Components.Cell = Lua.import('Module:Components/Table2/Cell')

return Components
