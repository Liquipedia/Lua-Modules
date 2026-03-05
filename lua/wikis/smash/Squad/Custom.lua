---
-- @Liquipedia
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Characters = Lua.import('Module:Characters')
local Class = Lua.import('Module:Class')
local SquadPlayerData = Lua.import('Module:SquadPlayer/data')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

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
	local columnVisibility = SquadUtils.analyzeColumnVisibility(players, props.status)

	props.children = Array.map(players, function(person)
		local game = person.game and mw.text.split(person.game:lower(), ',')[1] or tableGame
		local mains = SquadPlayerData.get{link = person.link, player = person.id, game = game} or person.mains
		person.flag = Variables.varDefault('nationality') or person.flag
		person.name = Variables.varDefault('name') or person.name

		local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {status = props.status, type = props.type}))
		squadPerson.extradata.game = game
		squadPerson.extradata.mains = mains
		SquadUtils.storeSquadPerson(squadPerson)

		local row = ExtendedSquadRow(squadPerson, columnVisibility) ---@type SmashSquadRow

		row:id():name()
		row:mains():date('joindate')

		if props.status == SquadUtils.SquadStatus.INACTIVE or props.status == SquadUtils.SquadStatus.FORMER_INACTIVE then
			row:date('inactivedate')
		end

		if props.status == SquadUtils.SquadStatus.FORMER or props.status == SquadUtils.SquadStatus.FORMER_INACTIVE then
			row:date('leavedate')
			row:newteam()
		end

		Variables.varDefine('nationality', '')
		Variables.varDefine('name', '')

		return row:create()

	end)

	return SquadContexts.ColumnVisibility{
		value = columnVisibility,
		children = {SquadContexts.RoleTitle{
			value = 'Main',
			children = {Squad(props)}
		}}
	}
end

return CustomSquad
