---
-- @Liquipedia
-- page=Module:GetTournamentPlayerStatsCopyPaste
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local HtmlWidgets = Lua.import('Module:Widget/Html')

---@class TournamentPlayerStatsCopyPaste
local CopyPaste = Class.new()

---@param args table
---@param key string
---@param default boolean
---@return boolean
local function readBool(args, key, default)
	local value = args[key]

	if value == nil or value == '' then
		return default
	end

	value = tostring(value):lower()

	if value == '1' or value == 'true' or value == 'yes' then
		return true
	end

	if value == '0' or value == 'false' or value == 'no' then
		return false
	end

	return default
end

---@param args table
---@return string[]
local function getStatFields(args)
	local stats = {}

	if readBool(args, 'games', false) then
		table.insert(stats, 'games')
	end
	if readBool(args, 'kills', true) then
		table.insert(stats, 'kills')
	end
	if readBool(args, 'assists', true) then
		table.insert(stats, 'assists')
	end
	if readBool(args, 'knocks', false) then
		table.insert(stats, 'knocks')
	end
	if readBool(args, 'damage', false) then
		table.insert(stats, 'damage')
	end
	if readBool(args, 'damageTaken', false) then
		table.insert(stats, 'damageTaken')
	end

	return stats
end

---@param statFields string[]
---@return string
local function makePlayerRow(statFields)
	local parts = {'{{Json|name='}

	for _, field in ipairs(statFields) do
		table.insert(parts, field .. '=')
	end

	return table.concat(parts, '|') .. '}}'
end

---@param display string
---@return Renderable
function CopyPaste._generateCopyPaste(display)
	return HtmlWidgets.Pre{
		classes = {'selectall'},
		children = mw.text.nowiki(display),
	}
end

---@param frame Frame
---@return Renderable
function CopyPaste.run(frame)
	local args = Arguments.getArgs(frame)

	local id = args.id or ''
	local tournament = args.tournament or ''
	local playerCount = tonumber(args.players) or 20
	local statFields = getStatFields(args)

	assert(id ~= '', 'GetTournamentPlayerStatsCopyPaste: missing id')
	assert(tournament ~= '', 'GetTournamentPlayerStatsCopyPaste: missing tournament')
	assert(playerCount > 0, 'GetTournamentPlayerStatsCopyPaste: players must be greater than 0')

	local rows = Array.mapRange(1, playerCount, function()
		return '|' .. makePlayerRow(statFields)
	end)

	local output = table.concat({
		'{{TournamentPlayerStatsStore',
		'|id=' .. id,
		'|tournament=' .. tournament,
		'|players={{Json',
		table.concat(rows, '\n'),
		'}}',
		'}}',
	}, '\n')

	return CopyPaste._generateCopyPaste(output)
end

return CopyPaste
