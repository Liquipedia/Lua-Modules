---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
Widgets.CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')
Widgets.GameCountdown = Lua.import('Module:Widget/Match/Summary/Ffa/GameCountdown')
Widgets.GameDetails = Lua.import('Module:Widget/Match/Summary/Ffa/GameDetails')
Widgets.GamesSchedule = Lua.import('Module:Widget/Match/Summary/Ffa/GamesSchedule')
Widgets.Header = Lua.import('Module:Widget/Match/Summary/Ffa/Header')
Widgets.MatchComment = Lua.import('Module:Widget/Match/Summary/Ffa/MatchComment')
Widgets.Mvp = Lua.import('Module:Widget/Match/Summary/Ffa/Mvp')
Widgets.PointsDistribution = Lua.import('Module:Widget/Match/Summary/Ffa/PointsDistribution')
Widgets.RankRange = Lua.import('Module:Widget/Match/Summary/Ffa/RankRange')
Widgets.Tab = Lua.import('Module:Widget/Match/Summary/Ffa/Tab')
Widgets.Table = Lua.import('Module:Widget/Match/Summary/Ffa/Table')
Widgets.TableHeader = Lua.import('Module:Widget/Match/Summary/Ffa/TableHeader')
Widgets.TableHeaderCell = Lua.import('Module:Widget/Match/Summary/Ffa/TableHeaderCell')
Widgets.TableRow = Lua.import('Module:Widget/Match/Summary/Ffa/TableRow')
Widgets.TableRowCell = Lua.import('Module:Widget/Match/Summary/Ffa/TableRowCell')
Widgets.Trophy = Lua.import('Module:Widget/Match/Summary/Ffa/Trophy')

return Widgets
