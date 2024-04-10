---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local OpponentLib = require('Module:OpponentLibraries')
local Opponent = OpponentLib.Opponent
local OpponentDisplay = OpponentLib.OpponentDisplay
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Widget = Lua.import('Module:Infobox/Widget/All')

local ICON_CAPTAIN = Icon.makeIcon{iconName = 'captain', hover = 'Captain'}
local ICON_SUBSTITUTE = Icon.makeIcon{iconName = 'substitute', hover = 'Substitute'}

---@class SquadRow
---@operator call(ModelRow): SquadRow
---@field children Widget[]
---@field model ModelRow
local SquadRow = Class.new(
	function(self, squadPerson)
		self.children = {}
		self.model = assert(squadPerson, 'No Squad Person supplied to the Row')
	end
)

SquadRow.specialTeamsTemplateMapping = {
	retired = 'Team/retired',
	inactive = 'Team/inactive',
	['passed away'] = 'Team/passed away',
	military = 'Team/military',
}

---@return self
function SquadRow:id()
	local content = {}
	local opponent = Opponent.resolve(
		Opponent.readOpponentArgs{
			self.model.id,
			flag = self.model.nationality,
			link = self.model.link,
			faction = self.model.extradata.faction,
			type = Opponent.solo,
		},
		nil, {syncPlayer = true}
	)
	table.insert(content, mw.html.create('b'):node(OpponentDisplay.InlineOpponent{opponent = opponent}))

	if self.model.role == 'Captain' then
		table.insert(content, '&nbsp;' .. ICON_CAPTAIN)
	end

	if self.model.role == 'Sub' then
		table.insert(content, '&nbsp;' .. ICON_SUBSTITUTE)
	end

	local cell = Widget.TableCellNew{
		classes = {'ID'},
		content = content,
	}

	local date = self.model.leavedate or self.model.inactivedate
	local hasTeam = self.model.extradata.loanedto and mw.ext.TeamTemplate.teamexists(self.model.extradata.loanedto)
	local hasTeamRole = hasTeam and self.model.extradata.loanedtorole
	local teamNode = Widget.TableCellNew{
		css = hasTeamRole and {'text-align', 'center'} or nil,
		content = {
			hasTeam and mw.ext.TeamTemplate.teamicon(self.model.extradata.loanedto, date) or nil,
			hasTeamRole and mw.html.create('small'):tag('i'):wikitext(self.model.extradata.loanedtorole) or nil,
		}
	}

	table.insert(self.children, cell)
	table.insert(self.children, teamNode)

	return self
end

---@return self
function SquadRow:name()
	table.insert(self.children, Widget.TableCellNew{
		classes = {'Name'},
		content = self.model.name and {
			mw.html.create('div'):addClass('MobileStuff'):wikitext('(', self.model.name, ')'),
			mw.html.create('div'):addClass('LargeStuff'):wikitext(self.model.name),
		} or nil
	})

	return self
end

---@return self
function SquadRow:role()
	table.insert(self.children, Widget.TableCellNew{
		classes = {'Position'},
		content = self.model.role and {
			mw.html.create('div'):addClass('MobileStuff'):wikitext('Role:&nbsp;'),
			mw.html.create('i'):wikitext('(' .. self.model.role .. ')'),
		} or nil,
	})

	return self
end

---Display Position and Role in a single cell
---@param args table
---@return self
function SquadRow:position(args)
	local content = {}

	if String.isNotEmpty(args.position) or String.isNotEmpty(args.role) then
		table.insert(content, mw.html.create('div'):addClass('MobileStuff'):wikitext('Position:&nbsp;'))

		if String.isNotEmpty(args.position) then
			table.insert(content, args.position)
			if String.isNotEmpty(args.role) then
				table.insert(content, '&nbsp;(' .. args.role .. ')')
			end
		elseif String.isNotEmpty(args.role) then
			table.insert(content, args.role)
		end
	end

	table.insert(self.children, Widget.TableCellNew{
		classes = {'Position'},
		content = content,
	})

	self.lpdbData.position = args.position
	self.lpdbData.role = args.role or self.lpdbData.role

	return self
end

---Display Position and Role in a single cell
---@param args table
---@return self
function SquadRow:position(args)
	local content = {}

	if String.isNotEmpty(args.position) or String.isNotEmpty(args.role) then
		table.insert(content, mw.html.create('div'):addClass('MobileStuff'):wikitext('Position:&nbsp;'))

		if String.isNotEmpty(args.position) then
			table.insert(content, args.position)
			if String.isNotEmpty(args.role) then
				table.insert(content, '&nbsp;(' .. args.role .. ')')
			end
		elseif String.isNotEmpty(args.role) then
			table.insert(content, args.role)
		end
	end

	table.insert(self.children, Widget.TableCellNew{
		classes = {'Position'},
		content = content,
	})

	self.lpdbData.position = args.position
	self.lpdbData.role = args.role or self.lpdbData.role

	return self
end

---@param field string
---@param cellTitle string?
---@return self
function SquadRow:date(field, cellTitle)
	table.insert(self.children, Widget.TableCellNew{
		classes = {'Date'},
		content = self.model[field] and {
			mw.html.create('div'):addClass('MobileStuffDate'):wikitext(cellTitle),
			mw.html.create('div'):addClass('Date'):tag('i'):wikitext(self.model[field]),
		} or nil
	})

	return self
end

---@return self
function SquadRow:newteam()
	local content = {}

	if String.isNotEmpty(self.model.newteam) or String.isNotEmpty(self.model.newteamrole) then
		local mobileStuffDiv = mw.html.create('div'):addClass('MobileStuff')
			:tag('i'):addClass('fa fa-long-arrow-right'):attr('aria-hidden', 'true'):done():wikitext('&nbsp;')
		table.insert(content, mobileStuffDiv)

		if String.isNotEmpty(self.model.newteam) then
			local newTeam = self.model.newteam
			if mw.ext.TeamTemplate.teamexists(newTeam) then
				local date = self.model.newteamdate or self.model.leavedate
				table.insert(content, mw.ext.TeamTemplate.team(newTeam, date))

			elseif self.options.useTemplatesForSpecialTeams then
				local newTeamTemplate = SquadRow.specialTeamsTemplateMapping[newTeam]
				if newTeamTemplate then
					table.insert(content, Template.safeExpand(mw.getCurrentFrame(), newTeamTemplate))
				end
			end

			if String.isNotEmpty(self.model.newteamrole) then
				table.insert(content, '&nbsp;')
				table.insert(content, mw.html.create('i'):tag('small'):wikitext('(' .. self.model.newteamrole .. ')'))
			end
		elseif not self.options.useTemplatesForSpecialTeams and String.isNotEmpty(self.model.newteamrole) then
			table.insert(content, mw.html.create('div'):addClass('NewTeamRole'):wikitext(self.model.newteamrole))
		end
	end

	table.insert(self.children, Widget.TableCellNew{
		classes = {'NewTeam'},
		content = content,
	})

	return self
end

---@return WidgetTableRowNew
function SquadRow:create()
	-- Set row background for certain roles
	local backgrounds = {'Player'}
	local role = string.lower(self.model.role or '')

	if role == 'sub' then
		table.insert(backgrounds, 'sub')
	elseif role:find('coach') then
		table.insert(backgrounds, role)
		table.insert(backgrounds, 'roster-coach')
	end

	return Widget.TableRowNew{
		classes = backgrounds,
		children = self.children,
	}
end

return SquadRow
