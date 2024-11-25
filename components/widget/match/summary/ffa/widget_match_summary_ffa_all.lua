---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.Header = Lua.import('Module:Widget/Match/Summary/Ffa/Header')
Widgets.CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')

return Widgets
