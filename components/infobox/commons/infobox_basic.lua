---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Basic
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Logic = require('Module:Logic')
local getArgs = require('Module:Arguments').getArgs

local Infobox = Lua.import('Module:Infobox', {requireDevIfEnabled = true})

local BasicInfobox = Class.new(
	function(self, frame)
		self.args = getArgs(frame)
		self.pagename = mw.title.getCurrentTitle().text
		self.name = self.args.name or self.pagename

		if self.args.wiki == nil then
			return error('Please provide a wiki!')
		end

		self.infobox = Infobox:create(frame, self.args.wiki, Logic.readBool(self.args.darkmodeforced))
	end
)

function BasicInfobox:createWidgetInjector()
	return nil
end

--- Allows for overriding this functionality
function BasicInfobox:addCustomCells(infobox, args)
	return infobox
end

--- Allows for overriding this functionality
function BasicInfobox:createBottomContent()
	return nil
end

--- Allows for overriding this functionality
function BasicInfobox:getWikiCategories(args)
	return {}
end

--- Allows for using this for customCells
function BasicInfobox:getAllArgsForBase(args, base, options)
	local foundArgs = {}
	if String.isEmpty(args[base]) and String.isEmpty(args[base .. '1']) then
		return foundArgs
	end

	options = options or {}
	local makeLink = Logic.readBool(options.makeLink)

	local baseArg = args[base] or args[base .. '1']
	if makeLink then
		local link = args[base .. 'link'] or args[base .. '1link'] or baseArg
		baseArg = '[[' .. link
			.. '|' .. baseArg .. ']]'
	end

	table.insert(foundArgs, baseArg)
	local index = 2

	while not String.isEmpty(args[base .. index]) do
		local indexedbase = args[base .. index]
		if makeLink then
			indexedbase = '[[' .. (args[base .. index .. 'link'] or indexedbase)
				.. '|' .. indexedbase .. ']]'
		end
		table.insert(foundArgs, indexedbase)
		index = index + 1
	end

	return foundArgs
end

return BasicInfobox
