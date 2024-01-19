---
-- @Liquipedia
-- wiki=smite
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local GodIcon = require('Module:GodIcon')
local GodNames = mw.loadData('Module:GodNames')
local Lua = require('Module:Lua')
local Region = require('Module:Region')
local Role = require('Module:Role')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local SIZE_GOD = '25x25px'

---@class SmiteInfoboxPlayer: Person
---@field role table
---@field role2 table
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)

	player:setWidgetInjector(CustomInjector(player))

	player.args.autoTeam = true
	player.role = Role.run({role = player.args.role})
	player.role2 = Role.run({role = player.args.role2})

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'history' then
		local automatedHistory = TeamHistoryAuto._results{
			convertrole = 'true',
			iconModule = 'Module:PositionIcon/data',
			player = self.pagename
		}

		if String.isNotEmpty(args.history) or automatedHistory then
			return {
				Title{name = 'History'},
				Center{content = {args.history}},
				Center{content = {automatedHistory}},
			}
		end
	elseif id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = {self.caller.role.display, self.caller.role2.display}}
		}
	elseif id == 'custom' then
		-- Signature Gods
		local godIcons = Array.map(self.caller:getAllArgsForBase(args, 'god'), function(god)
				return GodIcon.getImage{god, size = SIZE_GOD}
			end)
		table.insert(widgets, Cell{
			name = #godIcons > 1 and 'Signature Gods' or 'Signature God',
			content = {table.concat(godIcons, '&nbsp;')},
				})
	end
	return widgets
end

function CustomPlayer:adjustLPDB(lpdbData, args)
	lpdbData.extradata.isplayer = self.role.isPlayer or 'true'
	lpdbData.extradata.role = self.role.role
	lpdbData.extradata.role2 = self.role2.role

	-- store signature godes with standardized name
	for godIndex, god in ipairs(Player:getAllArgsForBase(args, 'god')) do
		lpdbData.extradata['signatureGod' .. godIndex] = GodNames[god:lower()]
	end

	lpdbData.region = String.nilIfEmpty(Region.name({region = args.region, country = args.country}))

	return lpdbData
end

return CustomPlayer
