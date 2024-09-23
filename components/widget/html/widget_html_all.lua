---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.Div = Lua.import('Module:Widget/Div')
Widgets.Span = Lua.import('Module:Widget/Span')
Widgets.Table = Lua.import('Module:Widget/Table')
Widgets.Td = Lua.import('Module:Widget/Td')
Widgets.Th = Lua.import('Module:Widget/Th')
Widgets.Tr = Lua.import('Module:Widget/Tr')

return Widgets
