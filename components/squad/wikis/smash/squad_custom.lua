---
-- @Liquipedia
-- wiki=smash
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
local Widget = require('Module:Infobox/Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local Injector = Lua.import('Module:Infobox/Widget/Injector')

local CustomSquad = {}
local CustomInjector = Class.new(Injector)

function CustomInjector:parse(id, widgets)
	if id == 'header_role' then
		return {
			Widget.TableCellNew{content = {'Main'}, header = true}
		}
	end

	return widgets
end

---@class SmashSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@return self
function ExtendedSquadRow:mains()
	local characters = {}
	Array.forEach(mw.text.split(self.model.extradata.mains or '', ','), function(main)
		table.insert(characters, Characters.GetIconAndName{main, game = self.model.extradata.game, large = true})
	end)

	table.insert(self.children, Widget.TableCellNew{
		css = {['text-align'] = 'center'},
		content = characters,
	})

	return self
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local args = Arguments.getArgs(frame)
	local squad = Squad(args, CustomInjector()):title():header()

	local tableGame = squad.args.game

	local players = SquadUtils.parsePlayers(squad.args)

	Array.forEach(players, function(person)
		local game = person.game and mw.text.split(person.game:lower(), ',')[1] or tableGame
		local mains = SquadPlayerData.get{link = person.link, player = person.id, game = game} or person.mains
		person.flag = Variables.varDefault('nationality') or person.flag
		person.name = Variables.varDefault('name') or person.name

		local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {type = squad.type}))
		squadPerson.extradata.game = game
		squadPerson.extradata.mains = mains
		SquadUtils.storeSquadPerson(squadPerson)

		local row = ExtendedSquadRow(squadPerson) ---@type SmashSquadRow

		row:id():name()
		row:mains():date('joindate', 'Join Date:&nbsp;')

		if squad.type == SquadUtils.SquadType.INACTIVE or squad.type == SquadUtils.SquadType.FORMER_INACTIVE then
			row:date('inactivedate', 'Inactive Date:&nbsp;')
		end

		if squad.type == SquadUtils.SquadType.FORMER or squad.type == SquadUtils.SquadType.FORMER_INACTIVE then
			row:date('leavedate', 'Leave Date:&nbsp;')
			row:newteam()
		end

		Variables.varDefine('nationality', '')
		Variables.varDefine('name', '')

		squad:row(row:create())

	end)

	return squad:create()
end

return CustomSquad
