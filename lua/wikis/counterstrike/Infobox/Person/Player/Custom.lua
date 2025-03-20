---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Game = Lua.import('Module:Game')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local BANNED = mw.loadData('Module:Banned')

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.history = player.args.team_history

	for steamKey, steamInput, steamIndex in Table.iter.pairsByPrefix(player.args, 'steam', {requireIndex = false}) do
		player.args['steamalternative' .. steamIndex] = steamInput
		player.args[steamKey] = nil
	end

	player.args.informationType = player.args.informationType or 'Player'

	player.args.banned = tostring(player.args.banned or '')

	player.gamesList = Array.filter(Game.listGames({ordered = true}), function (gameIdentifier)
			return player.args[gameIdentifier]
		end)

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		return {
			Cell {
				name = 'Games',
				content = Array.map(caller.gamesList, function (gameIdentifier)
						return Game.text{game = gameIdentifier}
					end)
			}
		}
	elseif id == 'status' then
		return {
			Cell{name = 'Status', content = caller:_getStatusContents(args)},
			Cell{name = 'Years Active (Player)', content = {args.years_active}},
			Cell{name = 'Years Active (Org)', content = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
			Cell{name = 'Years Active (Analyst)', content = {args.years_active_analyst}},
			Cell{name = 'Years Active (Talent)', content = {args.years_active_talent}},
		}
	elseif id == 'region' then
		return {}
	end

	return widgets
end

---@param args table
---@return table
function CustomPlayer:_getStatusContents(args)
	local statusContents = {}

	if String.isNotEmpty(args.status) then
		table.insert(statusContents, Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status)
	end

	if String.isNotEmpty(args.banned) then
		local banned = BANNED[string.lower(args.banned)]
		if not banned then
			table.insert(statusContents, '[[Banned Players|Multiple Bans]]')
		end

		Array.extendWith(statusContents, Array.map(self:getAllArgsForBase(args, 'banned'),
				function(item)
					return BANNED[string.lower(item)]
				end
			))
	end

	return statusContents
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	local typeCategory = self:getPersonType(self.args).category

	Array.forEach(self.gamesList, function (gameIdentifier)
			local prefix = Game.abbreviation{game = gameIdentifier} or Game.name{game = gameIdentifier}
			table.insert(categories, prefix .. ' ' .. typeCategory .. 's')
		end)

	if Table.isEmpty(self.gamesList) then
		table.insert(categories, 'Gameless Players')
	end

	return Array.append(categories,
		(self.role or {}).category,
		(self.role2 or {}).category,
		(self.role or {}).category2,
		(self.role2 or {}).category2
	)
end

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	local roleData = self.role
	if roleData then
		if roleData.coach then
			return {store = 'Coach', category = 'Coache'}
		elseif roleData.management then
			return {store = 'Staff', category = 'Manager'}
		elseif roleData.talent then
			return {store = 'Talent', category = 'Talent'}
		end
	end
	return {store = 'Player', category = 'Player'}
end

return CustomPlayer
