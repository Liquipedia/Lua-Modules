---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Types
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@class TournamentAppearancesConfig
---@field showPlacementInsteadOfTeam boolean
---@field limit integer
---@field isFormQuery boolean
---@field restrictToPlayersParticipatingIn string?
---@field restrictToFirstPrizePool boolean
---@field player boolean
---@field staff boolean
---@field conditions ConditionTree|string?
---@field tierTypes string[]
---@field tiers string[]
---@field startDate string|integer?
---@field endDate string|integer?
---@field pages string[]
---@field series string[]?
---todo: add stuff for opponent case

return {
	DEFAULT_TIERTYPES = {'General', 'School', ''},
	FORM_NAME = 'Player tournament appearances',
}
