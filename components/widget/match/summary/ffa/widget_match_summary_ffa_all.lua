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
Widgets.Tab = Lua.import('Module:Widget/Match/Summary/Ffa/Tab')
Widgets.PointsDistribution = Lua.import('Module:Widget/Match/Summary/Ffa/PointsDistribution')
Widgets.RankRange = Lua.import('Module:Widget/Match/Summary/Ffa/RankRange')
Widgets.Trophy = Lua.import('Module:Widget/Match/Summary/Ffa/Trophy')

return Widgets
