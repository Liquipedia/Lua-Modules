---
-- @Liquipedia
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
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
	local squadArgs = Arguments.getArgs(mw.getCurrentFrame())

	if squadStatus == SquadUtils.SquadStatus.ACTIVE then
		local isMain = Logic.readBool(squadArgs.main) or Logic.isEmpty(squadArgs.squad)
		squadPerson.extradata = Table.merge({
			ismain = tostring(isMain), --legacy for during conversion only!
			group = isMain and 'main' or 'additional',
		}, squadPerson.extradata)
	end
	squadPerson.newteamspecial = Logic.emptyOr(squadPerson.newteamspecial,
		Logic.readBool(person.retired) and 'retired' or nil,
		Logic.readBool(person.military) and 'military' or nil)

	SquadUtils.storeSquadPerson(squadPerson)

	local row = SquadRow(squadPerson)

	row:id():name():role():date('joindate', 'Join Date:&nbsp;')

	if squadStatus == SquadUtils.SquadStatus.INACTIVE or squadStatus == SquadUtils.SquadStatus.FORMER_INACTIVE then
		row:date('inactivedate', 'Inactive Date:&nbsp;')
	end
	if squadStatus == SquadUtils.SquadStatus.FORMER or squadStatus == SquadUtils.SquadStatus.FORMER_INACTIVE then
		row:date('leavedate', 'Leave Date:&nbsp;')
		row:newteam()
	end

	return row:create()
end

return CustomSquad
