---
-- @Liquipedia
-- page=Module:Infobox/Role
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class RoleInfobox: BasicInfobox
local Role = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Role.run(frame)
	local role = Role(frame)
	return role:createInfobox()
end

---@return string
function Role:createInfobox()
	local args = self.args

	if String.isEmpty(args.informationType) then
		args.informationType = 'Role'
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
	local roleIndex = (tonumber(Variables.varDefault('role_index')) or 0) + 1
	Variables.varDefine('role_index', roleIndex)

	local lpdbData = {
		objectName = 'role_' .. roleIndex .. '_' .. self.name,
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

return Role
