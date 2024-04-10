---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad():init(frame):title():header()

	local players = SquadUtils.parsePlayers(squad.args)

	Array.forEach(players, function(player)
		squad:row(CustomSquad._playerRow(player, squad.type))
	end)

	return squad:create()
end

---@param playerList table[]
---@param squadType integer
---@return Html?
function CustomSquad.runAuto(playerList, squadType)
	if #playerList == 0 then
		return
	end

	local squad = Squad():init{type = squadType}:title():header()

	Array.forEach(playerList, function(player)
		squad:row(CustomSquad._playerRow(SquadUtils.convertAutoParameters(player), squad.type))
	end)

	return squad:create()
end

---@param player table
---@param squadType SquadType
---@return WidgetTableRowNew
function CustomSquad._playerRow(player, squadType)
	local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(player, {type = squadType}))
	SquadUtils.storeSquadPerson(squadPerson)
	local row = SquadRow(squadPerson)

	row:id():name():role():date('joindate', 'Join Date:&nbsp;')

	if squadType == SquadUtils.SquadType.INACTIVE or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date('inactivedate', 'Inactive Date:&nbsp;')
	end

	if squadType == SquadUtils.SquadType.FORMER or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date('leavedate', 'Leave Date:&nbsp;')
		row:newteam()
	end

	return row:create()
end

return CustomSquad
