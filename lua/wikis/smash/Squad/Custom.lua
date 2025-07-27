---
-- @Liquipedia
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Characters = require('Module:Characters')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local SquadPlayerData = require('Module:SquadPlayer/data')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Widget = Lua.import('Module:Widget/All')
local Squad = Lua.import('Module:Widget/Squad/Core')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')
local SquadContexts = Lua.import('Module:Widget/Contexts/Squad')

local CustomSquad = {}

---@class SmashSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@return self
function ExtendedSquadRow:mains()
	local characters = {}
	Array.forEach(mw.text.split(self.model.extradata.mains or '', ','), function(main)
		table.insert(characters, Characters.GetIconAndName{main, game = self.model.extradata.game, large = true})
	end)

	table.insert(self.children, Widget.Td{
		css = {['text-align'] = 'center'},
		children = characters,
	})

	return self
end

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	local args = Arguments.getArgs(frame)
	local props = {
		status = SquadUtils.statusToSquadStatus(args.status) or SquadUtils.SquadStatus.ACTIVE,
		title = args.title,
		type = SquadUtils.TypeToSquadType[args.type] or SquadUtils.SquadType.PLAYER,
	}

	local tableGame = args.game

	local players = SquadUtils.parsePlayers(args)

	props.children = Array.map(players, function(person)
		local game = person.game and mw.text.split(person.game:lower(), ',')[1] or tableGame
		local mains = SquadPlayerData.get{link = person.link, player = person.id, game = game} or person.mains
		person.flag = Variables.varDefault('nationality') or person.flag
		person.name = Variables.varDefault('name') or person.name

		local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {status = props.status, type = props.type}))
		squadPerson.extradata.game = game
		squadPerson.extradata.mains = mains
		SquadUtils.storeSquadPerson(squadPerson)

		local row = ExtendedSquadRow(squadPerson) ---@type SmashSquadRow

		row:id():name()
		row:mains():date('joindate', 'Join Date:&nbsp;')

		if props.status == SquadUtils.SquadStatus.INACTIVE or props.status == SquadUtils.SquadStatus.FORMER_INACTIVE then
			row:date('inactivedate', 'Inactive Date:&nbsp;')
		end

		if props.status == SquadUtils.SquadStatus.FORMER or props.status == SquadUtils.SquadStatus.FORMER_INACTIVE then
			row:date('leavedate', 'Leave Date:&nbsp;')
			row:newteam()
		end

		Variables.varDefine('nationality', '')
		Variables.varDefine('name', '')

		return row:create()

	end)

	return SquadContexts.RoleTitle{
		value = 'Main',
		children = {Squad(props)}
	}
end

return CustomSquad
