---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Widget = require('Module:Widget/All')

local Squad = Lua.import('Module:Widget/Squad/Core')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')
local SquadContexts = Lua.import('Module:Widget/Contexts/Squad')

local CustomSquad = {}

---@class OverwatchSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@return self
function ExtendedSquadRow:number()
	table.insert(self.children, Widget.Td{
		classes = {'Number'},
		content = String.isNotEmpty(self.model.extradata.number) and {
			mw.html.create('div'):addClass('MobileStuff'):wikitext('Number:&nbsp;'),
			self.model.extradata.number,
		} or nil,
	})

	return self
end

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	local args = Arguments.getArgs(frame)
	local props = {
		type = SquadUtils.statusToSquadType(args.status) or SquadUtils.SquadType.ACTIVE,
		title = args.title,
	}
	local players = SquadUtils.parsePlayers(args)

	local showNumber = Array.any(players, Operator.property('number'))

	props.children = Array.map(players, function(player)
		return CustomSquad._playerRow(player, props.type, showNumber)
	end)

	return SquadContexts.HeaderName{
		value = function(widgets)
			table.insert(widgets, 1, Widget.Th{content = {'Name'}})
			return widgets
		end,
		children = {SquadContexts.Role{value = SquadUtils.positionHeader(), children = {Squad(props)}}},
	}
end

---@param playerList table[]
---@param squadType integer
---@param customTitle string?
---@return Widget
function CustomSquad.runAuto(playerList, squadType, customTitle)
	return SquadUtils.defaultRunAuto(playerList, squadType, Squad, SquadUtils.defaultRow(SquadRow), customTitle)
end

---@param person table
---@param squadType integer
---@param showNumber boolean
---@return WidgetTr
function CustomSquad._playerRow(person, squadType, showNumber)
	local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {type = squadType}))
	squadPerson.extradata.number = person.number
	SquadUtils.storeSquadPerson(squadPerson)

	local row = ExtendedSquadRow(squadPerson)

	row:id()
	if showNumber then
		row:number()
	end
	row:name():position():date('joindate', 'Join Date:&nbsp;')

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
