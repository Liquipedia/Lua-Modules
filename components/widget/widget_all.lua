---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.Breakdown = Lua.import('Module:Widget/Breakdown')
Widgets.Builder = Lua.import('Module:Widget/Builder')
Widgets.Cell = Lua.import('Module:Widget/Cell')
Widgets.Center = Lua.import('Module:Widget/Center')
Widgets.Chronology = Lua.import('Module:Widget/Chronology')
Widgets.Customizable = Lua.import('Module:Widget/Customizable')
Widgets.Error = Lua.import('Module:Widget/Error')
Widgets.Header = Lua.import('Module:Widget/Header')
Widgets.Links = Lua.import('Module:Widget/Links')
Widgets.Title = Lua.import('Module:Widget/Title')

return Widgets
