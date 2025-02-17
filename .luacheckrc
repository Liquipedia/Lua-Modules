std = {
	globals = {
		"mw",
	},
	read_globals = {
		"arg",
		"assert",
		"debug",
		"error",
		"getmetatable",
		"ipairs",
		"math",
		"next",
		"os",
		"package",
		"pairs",
		"pcall",
		"rawget",
		"rawset",
		"require",
		"select",
		"setmetatable",
		"string",
		"table",
		"tonumber",
		"tostring",
		"type",
		"unpack",
		"xpcall",
	}
}
exclude_files = {
	".install", -- package files
	".luarocks", -- package manager files
	"3rd/*", -- 3rd party
	"node_modules/*", -- to speedup run when running locally
}

-- https://luacheck.readthedocs.io/en/stable/warnings.html#list-of-warnings
ignore = {
	"212" -- unused argument
}

files["spec/*_spec.lua"].read_globals = {"GoldenTest", "SetActiveWiki", "allwikis"}
