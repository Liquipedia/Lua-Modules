---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Widget = require('Module:Widget/All')

local Squad = Lua.import('Module:Widget/Squad/Core')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')
local SquadContexts = Lua.import('Module:Widget/Contexts/Squad')

local CustomSquad = {}

---@class Dota2SquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@return self
function ExtendedSquadRow:activeteam()
	local activeTeam, activeTeamRole = self.model.extradata.activeteam, self.model.activeteamrole
	local date = self.model.inactivedate

	if not activeTeam then
		table.insert(self.children,Widget.Td{classes = {'NewTeam'}, content = {}})
		return self
	end

	local content = {}

	table.insert(content, mw.ext.TeamTemplate.team(activeTeam, date))

	if activeTeamRole then
		table.insert(content, '&nbsp;')
		table.insert(content, mw.html.create('i'):tag('small'):wikitext('(' .. activeTeamRole .. ')'))
	end

	table.insert(self.children,
		Widget.Td{classes = {'NewTeam'}, content = content}
	)

	return self
end

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	return SquadContexts.InactiveSection{
		value = function(widgets)
			table.insert(widgets, Widget.Th{content = {'Inactive Date'}})
			return widgets
		end,
		children = {SquadUtils.defaultRunManual(frame, Squad, CustomSquad._playerRow)}
	}
end

function CustomSquad._playerRow(person, squadType)
	local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {type = squadType}))
	squadPerson.extradata.activeteam = person.activeteam
	squadPerson.extradata.activeteamrole = person.activeteamrole
	SquadUtils.storeSquadPerson(squadPerson)

	local row = ExtendedSquadRow(squadPerson)
	row:id()
	row:name()
	row:position()
	row:date('joindate', 'Join Date:&nbsp;')

	if squadType == SquadUtils.SquadType.INACTIVE or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date('inactivedate', 'Inactive Date:&nbsp;')
		row:activeteam()
	end
	if squadType == SquadUtils.SquadType.FORMER or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date('leavedate', 'Leave Date:&nbsp;')
		row:newteam()
	end

	return row:create()
end

return CustomSquad
