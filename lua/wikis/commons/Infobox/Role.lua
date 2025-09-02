---
-- @Liquipedia
-- page=Module:Infobox/Role
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Hotkey = Lua.import('Module:Hotkey')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class RoleInfobox: BasicInfobox
local Role = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Role.run(frame)
	local skill = Role(frame)
	return skill:createInfobox()
end

---@return string
function Role:createInfobox()
	local args = self.args

	if String.isEmpty(args.informationType) then
		args.informationType = 'Class'
	end

	local widgets = {
		Header{
			name = self:nameDisplay(args),
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = args.informationType .. ' Information'},
		Customizable{id = 'custom', children = {}},
		Center{children = {args.footnotes}},
	}

	if Namespace.isMain() then
		local categories = self:getCategories(args)
		self:categories(unpack(categories))
		self:_setLpdbData(args)
	end

	return self:build(widgets)
end

---@param args table
---@return string?
function Role:nameDisplay(args)
	return args.name
end

--- Allows for overriding this functionality
---@param args table
---@return string[]
function Role:getCategories(args)
	return {}
end

---@param args table
function Role:_setLpdbData(args)
	local skillIndex = (tonumber(Variables.varDefault('skill_index')) or 0) + 1
	Variables.varDefine('skill_index', skillIndex)

	local lpdbData = {
		objectName = 'skill_' .. skillIndex .. '_' .. self.name,
		name = args.name,
		type = args.informationType,
		image = args.image,
		imagedark = args.imagedark,
		extradata = {},
	}
	lpdbData = self:addToLpdb(lpdbData, args)
	local objectName = Table.extract(lpdbData, 'objectName')

	mw.ext.LiquipediaDB.lpdb_datapoint(objectName, Json.stringifySubTables(lpdbData))
end

---@param lpdbData table
---@param args table
---@return table
function Role:addToLpdb(lpdbData, args)
	return lpdbData
end

---@param args table
---@return string?
function Role:_getHotkeys(args)
	local display
	if not String.isEmpty(args.hotkey) then
		if not String.isEmpty(args.hotkey2) then
			display = Hotkey.hotkey2{hotkey1 = args.hotkey, hotkey2 = args.hotkey2, seperator = 'slash'}
		else
			display = Hotkey.hotkey{hotkey = args.hotkey}
		end
	end

	return display
end

return Role
