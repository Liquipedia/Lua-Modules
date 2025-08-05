---
-- @Liquipedia
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Squad = Lua.import('Module:Widget/Squad/Core')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	return SquadUtils.defaultRunManual(frame, Squad, CustomSquad._playerRow)
end

---@param players table[]
---@param squadStatus SquadStatus
---@param squadType SquadType
---@param customTitle string?
---@return Widget
function CustomSquad.runAuto(players, squadStatus, squadType, customTitle)
	return SquadUtils.defaultRunAuto(
		players,
		squadStatus,
		squadType,
		Squad,
		CustomSquad._playerRow,
		customTitle,
		CustomSquad.personMapper
	)
end

---@param person table
---@return table
function CustomSquad.personMapper(person)
	local newPerson = SquadUtils.convertAutoParameters(person)
	newPerson.faction = Logic.emptyOr(person.thisTeam.position, person.newTeam.position)
	return newPerson
end

---@param person table
---@param squadStatus SquadStatus
---@param squadType SquadType
---@return Widget
function CustomSquad._playerRow(person, squadStatus, squadType)
	local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {status = squadStatus, type = squadType}))
	if Logic.isEmpty(squadPerson.newteam) then
		if Logic.readBool(person.retired) then
			squadPerson.newteamspecial = 'retired'
		elseif Logic.readBool(person.military) then
			squadPerson.newteamspecial = 'military'
		end
	end
	SquadUtils.storeSquadPerson(squadPerson)

	local row = SquadRow(squadPerson)
	row:id()
	row:name()
	row:role()
	row:date('joindate', 'Join Date:&nbsp;')

	if squadStatus == SquadUtils.SquadStatus.FORMER then
		row:date('leavedate', 'Leave Date:&nbsp;')
		row:newteam()
	elseif squadStatus == SquadUtils.SquadStatus.INACTIVE then
		row:date('inactivedate', 'Inactive Date:&nbsp;')
	end

	return row:create()
end

return CustomSquad
