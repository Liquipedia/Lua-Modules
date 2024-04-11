---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local OpponentLib = require('Module:OpponentLibraries')
local Opponent = OpponentLib.Opponent
local OpponentDisplay = OpponentLib.OpponentDisplay
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local SquadUtils = Lua.import('Module:Squad/Utils')
local Widget = Lua.import('Module:Infobox/Widget/All')

local ICON_CAPTAIN = '[[File:Captain Icon.png|18px|baseline|Captain|link=Category:Captains|alt=Captain'
	.. '|class=player-role-icon]]'
local ICON_SUBSTITUTE = '[[File:Substitution.png|18px|baseline|Sub|link=|alt=Substitution|class=player-role-icon]]'

---@class SquadRow
---@operator call: SquadRow
---@field children Widget[]
---@field options {useTemplatesForSpecialTeams: boolean?}
---@field backgrounds string[]
---@field lpdbData table
local SquadRow = Class.new(
	function(self, options)
		self.options = options or {}
		self.children = {}
		self.backgrounds = {'Player'}

		self.lpdbData = {type = SquadUtils.defaultPersonType}
	end
)

SquadRow.specialTeamsTemplateMapping = {
	retired = 'Team/retired',
	inactive = 'Team/inactive',
	['passed away'] = 'Team/passed away',
	military = 'Team/military',
}

---@param args table
---@return self
function SquadRow:id(args)
	if String.isEmpty(args[1]) then
		error('Something is off with your input!')
	end


	local content = {}
	local opponent = Opponent.resolve(
		Opponent.readOpponentArgs(Table.merge(args, {type = Opponent.solo})),
		nil, {syncPlayer = true}
	)
	table.insert(content, mw.html.create('b'):node(OpponentDisplay.InlineOpponent{opponent = opponent}))

	if String.isNotEmpty(args.captain) then
		table.insert(content, '&nbsp;' .. ICON_CAPTAIN)
		self.lpdbData.role = 'Captain'
	end

	if args.role == 'sub' then
		table.insert(content, '&nbsp;' .. ICON_SUBSTITUTE)
	end

	if String.isNotEmpty(args.name) then
		table.insert(content, '<br>')
		table.insert(content, mw.html.create('small'):tag('i'):wikitext(args.name))
		self.lpdbData.name = args.name
	end

	local cell = Widget.TableCellNew{
		classes = {'ID'},
		content = content,
	}

	local date = String.nilIfEmpty(ReferenceCleaner.clean(args.date))
	local hasTeam = args.team and mw.ext.TeamTemplate.teamexists(args.team)
	local hasTeamRole = hasTeam and args.teamrole
	local teamNode = Widget.TableCellNew{
		css = hasTeamRole and {'text-align', 'center'},
		content = {
			hasTeam and mw.ext.TeamTemplate.teamicon(args.team, date) or nil,
			hasTeamRole and mw.html.create('small'):tag('i'):wikitext(args.teamrole) or nil,
		}
	}

	table.insert(self.children, cell)
	table.insert(self.children, teamNode)

	self.lpdbData.id = args[1]
	self.lpdbData.nationality = Flags.CountryName(args.flag)
	self.lpdbData.link = mw.ext.TeamLiquidIntegration.resolve_redirect(args.link or args[1])

	return self
end

---@param args table
---@return self
function SquadRow:name(args)
	table.insert(self.children, Widget.TableCellNew{
		classes = {'Name'},
		content = {
			args.name and mw.html.create('div'):addClass('MobileStuff'):wikitext('(', args.name, ')') or nil,
			args.name and mw.html.create('div'):addClass('LargeStuff'):wikitext(args.name) or nil,
		}
	})

	self.lpdbData.name = args.name

	return self
end

---Position and Role shouldn't both be used, only one
---@param args table
---@return self
function SquadRow:role(args)
	table.insert(self.children, Widget.TableCellNew{
		classes = {'Position'},
		content = String.isNotEmpty(args.role) and {
			mw.html.create('div'):addClass('MobileStuff'):wikitext('Role:&nbsp;'),
			mw.html.create('i'):wikitext('(' .. args.role .. ')'),
		} or nil,
	})

	self.lpdbData.role = args.role or self.lpdbData.role

	-- Set row background for certain roles
	local role = string.lower(args.role or '')

	if role == 'sub' then
		table.insert(self.backgrounds, 'sub')
	elseif role:find('coach') then
		table.insert(self.backgrounds, role)
		table.insert(self.backgrounds, 'roster-coach')
	end

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

---@param dateValue string?
---@param cellTitle string?
---@param lpdbColumn string
---@return self
function SquadRow:date(dateValue, cellTitle, lpdbColumn)
	table.insert(self.children, Widget.TableCellNew{
		classes = {'Date'},
		content = String.isNotEmpty(dateValue) and {
			mw.html.create('div'):addClass('MobileStuffDate'):wikitext(cellTitle),
			mw.html.create('div'):addClass('Date'):tag('i'):wikitext(dateValue),
		}
		or nil
	})

	self.lpdbData[lpdbColumn] = ReferenceCleaner.clean(dateValue)

	return self
end

---@param args table
---@return self
function SquadRow:newteam(args)
	local content = {}

	if String.isNotEmpty(args.newteam) or String.isNotEmpty(args.newteamrole) then
		local mobileStuffDiv = mw.html.create('div'):addClass('MobileStuff')
			:tag('i'):addClass('fa fa-long-arrow-right'):attr('aria-hidden', 'true'):done():wikitext('&nbsp;')
		table.insert(content, mobileStuffDiv)

		if String.isNotEmpty(args.newteam) then
			local newTeam = args.newteam
			if mw.ext.TeamTemplate.teamexists(newTeam) then
				local date = args.newteamdate or ReferenceCleaner.clean(args.leavedate)
				table.insert(content, mw.ext.TeamTemplate.team(newTeam, date))

				self.lpdbData.newteam = mw.ext.TeamTemplate.teampage(newTeam)
				self.lpdbData.newteamtemplate = mw.ext.TeamTemplate.raw(newTeam, date).templatename
			elseif self.options.useTemplatesForSpecialTeams then
				local newTeamTemplate = SquadRow.specialTeamsTemplateMapping[newTeam]
				if newTeamTemplate then
					table.insert(content, Template.safeExpand(mw.getCurrentFrame(), newTeamTemplate))
				end
			end

			if String.isNotEmpty(args.newteamrole) then
				table.insert(content, '&nbsp;')
				table.insert(content, mw.html.create('i'):tag('small'):wikitext('(' .. args.newteamrole .. ')'))
			end
		elseif not self.options.useTemplatesForSpecialTeams and String.isNotEmpty(args.newteamrole) then
			table.insert(content, mw.html.create('div'):addClass('NewTeamRole'):wikitext(args.newteamrole))
		end
	end

	table.insert(self.children, Widget.TableCellNew{
		classes = {'NewTeam'},
		content = content,
	})

	return self
end

---@param type string
---@return self
function SquadRow:setType(type)
	type = type:lower()
	if Table.includes(SquadUtils.validPersonTypes, type) then
		self.lpdbData.type = type
	end
	return self
end

---@param status integer
---@return self
function SquadRow:status(status)
	self.lpdbData.status = SquadUtils.SquadTypeToStorageValue[status]
	return self
end

---@param extradata table
---@return self
function SquadRow:setExtradata(extradata)
	self.lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(extradata)
	return self
end

---@param objectName string
---@return WidgetTableRowNew
function SquadRow:create(objectName)
	if not Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		mw.ext.LiquipediaDB.lpdb_squadplayer(objectName, self.lpdbData)
	end

	return Widget.TableRowNew{
		classes = self.backgrounds,
		children = self.children,
	}
end

return SquadRow
