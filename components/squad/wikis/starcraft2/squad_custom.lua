---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
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
	local squadArgs = Arguments.getArgs(mw.getCurrentFrame())

	if squadType == SquadUtils.SquadType.ACTIVE then
		local isMain = Logic.readBool(squadArgs.main) or Logic.isEmpty(squadArgs.squad)
		squadPerson.extradata = Table.merge({ismain = tostring(isMain)}, squadPerson.extradata)
	end
	squadPerson.newteamspecial = Logic.emptyOr(squadPerson.newteamspecial,
		Logic.readBool(person.retired) and 'retired' or nil,
		Logic.readBool(person.military) and 'military' or nil)

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
