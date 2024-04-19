---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	return SquadUtils.defaultRunManual(frame, Squad, CustomSquad._playerRow)
end

---@param playerList table[]
---@param squadType integer
---@return Html?
function CustomSquad.runAuto(playerList, squadType)
	return SquadUtils.defaultRunAuto(playerList, squadType, Squad, CustomSquad._playerRow, nil, CustomSquad.personMapper)
end

---@param person table
---@return table
function CustomSquad.personMapper(person)
	local newPerson = SquadUtils.convertAutoParameters(person)
	newPerson.faction = Logic.emptyOr(person.thisTeam.position, person.newTeam.position)
	return newPerson
end

---@param person table
---@param squadType integer
---@return WidgetTableRowNew
function CustomSquad._playerRow(person, squadType)
	local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {type = squadType}))
	if Logic.isEmpty(squadPerson.newteam) then
		if Logic.readBool(person.retired) then
			squadPerson.newteam = 'retired'
		elseif Logic.readBool(person.military) then
			squadPerson.newteam = 'military'
		end
	end
	SquadUtils.storeSquadPerson(squadPerson)

	local row = SquadRow(squadPerson)
	row:id()
	row:name()
	row:role()
	row:date('joindate', 'Join Date:&nbsp;')

	if squadType == SquadUtils.SquadType.FORMER then
		row:date('leavedate', 'Leave Date:&nbsp;')
		row:newteam()
	elseif squadType == SquadUtils.SquadType.INACTIVE then
		row:date('inactivedate', 'Inactive Date:&nbsp;')
	end

	return row:create()
end

return CustomSquad
