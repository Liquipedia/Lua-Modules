---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.CharacterBanTable = Lua.import('Module:Widget/Match/Summary/CharacterBanTable')
Widgets.Characters = Lua.import('Module:Widget/Match/Summary/Characters')
Widgets.Character = Lua.import('Module:Widget/Match/Summary/Character')
Widgets.MatchPageLink = Lua.import('Module:Widget/Match/Summary/MatchPageLink')
Widgets.Mvp = Lua.import('Module:Widget/Match/Summary/Mvp')

return Widgets
