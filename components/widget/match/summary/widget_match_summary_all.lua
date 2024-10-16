---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.MatchPageLink = Lua.import('Module:Widget/Match/Summary/MatchPageLink')
Widgets.Mvp = Lua.import('Module:Widget/Match/Summary/Mvp')

return Widgets
