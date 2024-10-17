---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.Abbr = Lua.import('Module:Widget/Html/Abbr')
Widgets.Center = Lua.import('Module:Widget/Html/Center')
Widgets.Div = Lua.import('Module:Widget/Html/Div')
Widgets.Fragment = Lua.import('Module:Widget/Html/Fragment')
Widgets.Li = Lua.import('Module:Widget/Html/Li')
Widgets.Span = Lua.import('Module:Widget/Html/Span')
Widgets.Table = Lua.import('Module:Widget/Html/Table')
Widgets.Td = Lua.import('Module:Widget/Html/Td')
Widgets.Th = Lua.import('Module:Widget/Html/Th')
Widgets.Tr = Lua.import('Module:Widget/Html/Tr')
Widgets.Ul = Lua.import('Module:Widget/Html/Ul')

return Widgets
