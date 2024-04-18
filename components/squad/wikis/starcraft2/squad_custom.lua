---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local args = Arguments.getArgs(frame)
	local squad = Squad():init(args):title():header()

	local isFormer = squad.type == SquadUtils.SquadType.FORMER
	local isInactive = squad.type == SquadUtils.SquadType.INACTIVE
	local isMainSquad = Logic.readBool(args.main)
	local squadName = args.squad or mw.title.getCurrentTitle().prefixedText
	local status = (isFormer and 'former')
		or (isInactive and 'inactive')
		or (isMainSquad and 'main')
		or 'active'

	local players = SquadUtils.parsePlayers(squad.args)

	players = Array.map(players, function(player)
		if not player then return player end
		player.faction = Faction.read(player.race)
		if isFormer then
			player.newteam = String.nilIfEmpty(player.newteam) or
				Logic.readBool(player.retired) and 'retired' or
				Logic.readBool(player.military) and 'military' or nil
		end
		return player
	end)

	Array.forEach(players, function(person)
		local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {type = squad.type}))
		squadPerson.extradata.faction = person.faction
		squadPerson.extradata.squadname = squadName
		squadPerson.extradata.status = status
		local row = SquadRow(squadPerson)
			:id()
			:name()
			:role()
			:date('joindate', 'Join Date:&nbsp;')

		if isFormer then
			row:date('leavedate', 'Leave Date:&nbsp;')
			row:newteam()
		elseif isInactive then
			row:date('inactivedate', 'Inactive Date:&nbsp;')
		end

		squad:row(row:create())
	end)

	return squad:create()
end

return CustomSquad
