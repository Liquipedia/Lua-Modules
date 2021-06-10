std = {
	read_globals = {
		"mw",
		"require",
		"error",
		"type",
		"table",
		"ipairs",
		"pairs",
		"string",
		"tostring",
		"tonumber",
		"math",
		"assert",
		"os"
	}
}
exclude_files = {
	".install", -- package files
	".luarocks" -- package manager files
}

-- https://luacheck.readthedocs.io/en/stable/warnings.html#list-of-warnings
ignore = {
	"212" -- unused argument
}
