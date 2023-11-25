--
-- Name:        _preload.lua
-- Purpose:     Define the premake action.
-- Author:      Ryan Pusztai
-- Modified by: Andrea Zanellato
--              Andrew Gough
--              Manu Evans
--              Yehonatan Ballas
--              Jan "GamesTrap" Schürkamp
-- Created:     2013/05/06
-- Updated:     2023/11/25
-- Copyright:   (c) 2008-2020 Jason Perkins and the Premake project
--              (c) 2022-2023 Jan "GamesTrap" Schürkamp
--

local p = premake

newaction
{
	trigger         = "vscode",
	shortname       = "VSCode",
	description     = "Generate Visual Studio Code workspace",

	onWorkspace = function(wks)
		p.modules.vscode.generateWorkspace(wks)
	end,
}

return function(cfg)
	return (_ACTION == "vscode")
end
