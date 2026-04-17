---
-- @Liquipedia
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local SquadController = Lua.import('Module:Features/Squad/Controller')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	local args = Arguments.getArgs(frame)
	local squadData = SquadUtils.readWrapperArgs(args)

	squadData.players = Array.forEach(squadData.players, function(player)
		local inputId = player.id --[[@as number]]
		player.race = CustomSquad._queryTLPD(inputId, 'race') or player.race
		player.id = CustomSquad._queryTLPD(inputId, 'name') or player.id
		player.link = player.link or player.altname or player.id
		player.team = CustomSquad._queryTLPD(inputId, 'team_name')
		player.name = (CustomSquad._queryTLPD(inputId, 'name_korean') or '') .. ' ' ..
			(CustomSquad._queryTLPD(inputId, 'name_romanized') or player.name or '')
	end)
	return SquadController.execute(squadData)
end

---@param id number?
---@param value string
---@return string?
function CustomSquad._queryTLPD(id, value)
	if not Logic.isNumeric(id) then
		return
	end

	return String.nilIfEmpty(mw.getCurrentFrame():callParserFunction{
		name = '#external_info:tlpd_player',
		args = {id, value}
	})
end

return CustomSquad
