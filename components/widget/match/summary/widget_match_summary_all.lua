---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.Body = Lua.import('Module:Widget/Match/Summary/Body')
Widgets.Break = Lua.import('Module:Widget/Match/Summary/Break')
Widgets.Casters = Lua.import('Module:Widget/Match/Summary/Casters')
Widgets.CharacterBanTable = Lua.import('Module:Widget/Match/Summary/CharacterBanTable')
Widgets.Characters = Lua.import('Module:Widget/Match/Summary/Characters')
Widgets.Character = Lua.import('Module:Widget/Match/Summary/Character')
Widgets.GameCenter = Lua.import('Module:Widget/Match/Summary/GameCenter')
Widgets.GameComment = Lua.import('Module:Widget/Match/Summary/GameComment')
Widgets.GameWinLossIndicator = Lua.import('Module:Widget/Match/Summary/GameWinLossIndicator')
Widgets.MapVeto = Lua.import('Module:Widget/Match/Summary/MapVeto')
Widgets.MatchComment = Lua.import('Module:Widget/Match/Summary/MatchComment')
Widgets.MatchPageLink = Lua.import('Module:Widget/Match/Summary/MatchPageLink')
Widgets.Mvp = Lua.import('Module:Widget/Match/Summary/Mvp')
Widgets.Row = Lua.import('Module:Widget/Match/Summary/Row')

return Widgets
