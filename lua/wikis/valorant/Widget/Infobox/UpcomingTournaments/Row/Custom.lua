---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Widget/Infobox/UpcomingTournaments/Row/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local UpcomingTournamentsRow = Lua.import('Module:Widget/Infobox/UpcomingTournaments/Row')

---@class ValorantUpcomingTournamentsRow: UpcomingTournamentsRow
---@operator call(table): ValorantUpcomingTournamentsRow
local ValorantUpcomingTournamentsRow = Class.new(UpcomingTournamentsRow)

---@protected
---@return boolean
function ValorantUpcomingTournamentsRow:isHighlighted()
	return self.props.data.publishertier == 'highlighted'
end

return ValorantUpcomingTournamentsRow
