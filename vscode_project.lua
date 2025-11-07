--
-- Name:        vscode_project.lua
-- Purpose:     Generate a vscode C/C++ project file.
-- Author:      Ryan Pusztai
-- Modified by: Andrea Zanellato
--              Manu Evans
--              Tom van Dijck
--              Yehonatan Ballas
--              Jan "GamesTrap" Schürkamp
-- Created:     2013/05/06
-- Updated:     2025/11/04
-- Copyright:   (c) 2008-2020 Yehonatan Ballas, Jason Perkins and the Premake project
--              (c) 2022-2025 Jan "GamesTrap" Schürkamp
--

local p = premake
local tree = p.tree
local project = p.project
local config = p.config
local vscode = p.modules.vscode
vscode.project = {}
local m = vscode.project

local function GetThreadCount()
	local threads = 0

	-- Check command-line arguments for threads override
	for i, arg in ipairs(_ARGS) do
		if (arg == "--threads" or arg == "-t") and _ARGS[i + 1] then
			threads = tonumber(_ARGS[i + 1]) or 0
			break
		end
	end

	if threads > 0 then
		return threads
	end

	-- Automatic threads detection
	if os.host() == "windows" then
		local result = os.outputof("wmic cpu get NumberOfLogicalProcessors")
		for thread in result:gmatch("%d+") do
			threads = threads + (tonumber(thread) or 0)
		end
	else
		local result = os.outputof("nproc")
		threads = tonumber(result) or 0
	end

	if threads <= 0 then
		threads = 1
	end

	return threads
end

local function GetCompileCommand(system, action, cfgName, prjName, threadCount, all)
	local threadArg = string.format("-j%s", threadCount)

	local cmd = ""
	if system == "windows" then
		cmd = "cls && "
	else
		cmd = "clear && time "
	end

	if action == "make" then
		return cmd .. string.format("make config=%s %s %s", string.lower(cfgName), all and "all" or prjName, threadArg)
	elseif action == "ninja" then
		return cmd .. string.format("ninja %s %s", all and cfgName or string.format("%s_%s", prjName, cfgName), threadArg)
	elseif action == "vs" and system == "windows" then
		return cmd .. "msbuild"
	end

	return nil
end

local function GetVSArgs(wksName, cfgName, target, threadCount, all)
	if _OPTIONS["action"] ~= "vs" then
		return {}
	end

	return
	{
		string.format('/m:%s', threadCount),
		string.format('${workspaceRoot}/%s.sln', wksName),
		string.format('/p:Configuration=%s', cfgName),
		all and '/t:Build' or string.format('/t:%s', target)
	}
end

function m.vscode_c_cpp_properties(prj, isLast)
	local cdialect = prj.cdialect and string.lower(prj.cdialect) or "${default}"
	local cppdialect = prj.cppdialect and string.lower(prj.cppdialect) or "${default}"

	local cfgIdx = 1
	for cfg in project.eachconfig(prj) do
		p.push('{')
		p.w('"name": "%s (%s)",', prj.name, cfg.name)
		p.w('"includePath":')
		p.push('[')
		p.w('"${workspaceFolder}/**"%s', (#cfg.includedirs > 0 or #cfg.externalincludedirs > 0) and ',' or '')

		if #cfg.includedirs > 0 or #cfg.externalincludedirs > 0 then
			for idx, includedir in ipairs(cfg.includedirs) do
				if idx == #cfg.includedirs and #cfg.externalincludedirs == 0 then
					p.w('"%s"', includedir)
				else
					p.w('"%s",', includedir)
				end
			end
			for idx, includedir in ipairs(cfg.externalincludedirs) do
				if idx == #cfg.externalincludedirs then
					p.w('"%s"', includedir)
				else
					p.w('"%s",', includedir)
				end
			end
		end

		p.pop('],')
		p.w('"defines":')
		p.push('[')

		for defineIdx, define in ipairs(cfg.defines) do
			if defineIdx == #cfg.defines then
				p.w('"%s"', define:gsub('"','\\"'))
			else
				p.w('"%s",', define:gsub('"','\\"'))
			end
		end

		p.pop('],')
		p.w('"cStandard": "%s",', cdialect)
		p.w('"cppStandard": "%s",', cppdialect)
		p.w('"intelliSenseMode": "${default}"', cppdialect)

		if isLast and cfgIdx == #prj._cfglist then
			p.pop('}')
		else
			p.pop('},')
		end

		cfgIdx = cfgIdx + 1
	end
end

function m.vscode_launch(prj, isLast)
	local target = path.getrelative(prj.workspace.location, prj.location)
	local gdbPath = (os.host() ~= "windows") and os.outputof("which gdb") or nil

	local cfgIdx = 1
	for cfg in project.eachconfig(prj) do
		if cfg.kind ~= "ConsoleApp" and cfg.kind ~= "WindowedApp" then --Ignore non executable configuration(s) in launch.json
			cfgIdx = cfgIdx + 1
			goto continue
		end

		local programPath = path.getrelative(prj.workspace.location, cfg.buildtarget.abspath)
		local name = string.format("%s (%s)", prj.name, cfg.name)

		p.push('{')

		p.w('"name": "Run %s",', name)
		p.w('"request": "launch",')
		p.w('"type": "cppdbg",')
		p.w('"program": "${workspaceRoot}/%s",', programPath)
		if os.target ~= "linux" then
			p.w('"linux":')
			p.push('{')

			p.w('"externalConsole": true%s', gdbPath and ',' or '')
			if gdbPath then
				p.w('"miDebuggerPath": "%s",', gdbPath)
			end
			p.w('"MIMode": "gdb",')
			p.w('"setupCommands":')
			p.push('[')
			p.push('{')

			p.w('"text": "-enable-pretty-printing",')
			p.w('"description": "enable pretty printing",')
			p.w('"ignoreFailures": true')

			p.pop('},')
			p.pop('],')
			p.pop('},')
		elseif os.target == "windows" then
			p.w('"windows":')
			p.push('{')

			p.w('"console": "externalTerminal')

			p.pop('},')
		end

		p.w('"args": [],')
		p.w('"stopAtEntry": false,')
		p.w('"cwd": "${workspaceFolder}/%s",', target)
		p.w('"environment": [],')
		p.w('"preLaunchTask": "Build %s"', name)

		if isLast and cfgIdx == #prj._cfglist then
			p.pop('}')
		else
			p.pop('},')
		end

		cfgIdx = cfgIdx + 1

		::continue::
	end
end

local function GenerateTasks(cfgs, cfgsSize, nameFn, cmdFn, argsFn, isLast)
	local threadCount = GetThreadCount()

	local cfgIdx = 1
	for cfg in cfgs do
		local buildName = nameFn(cfg)

		p.push('{')

		p.w('"label": "%s",', buildName)
		p.w('"type": "shell",')

		local cmd = cmdFn(os.target(), _OPTIONS["action"], cfg.name, threadCount)
		if os.target() ~= "windows" then
			p.w('"linux":')
			p.push('{')

			p.w('"command": "%s",', cmd)
			p.w('"problemMatcher": "$gcc"')

			p.pop('},')
		else
			p.w('"windows":')
			p.push('{')

			p.w('"command": "%s",', cmd)
			p.w('"args":')
			p.push('[')

			local args = argsFn(cfg, threadCount)
			for argIdx, arg in ipairs(argsFn(cfg, threadCount)) do
				p.w('"%s"%s', arg, argIdx == #args and ',' or '')
			end
			p.pop('],')

			p.w('"problemMatcher": "$msCompile"')

			p.pop('},')
		end

		p.w('"group":')
		p.push('{')

		p.w('"kind": "build"')

		p.pop('}')

		if isLast and cfgIdx == cfgsSize then
			p.pop('}')
		else
			p.pop('},')
		end

		cfgIdx = cfgIdx + 1
	end
end

function m.vscode_tasks(prj)
	local target = path.translate(path.getrelative(prj.workspace.location, prj.location))
	return GenerateTasks(project.eachconfig(prj), #prj._cfglist,
		function(cfg)
			return string.format("Build %s (%s)", prj.name, cfg.name)
		end,
		function(sys, action, cfgName, threadCount)
			return GetCompileCommand(sys, action, cfgName, prj.name, threadCount, false)
		end,
		function(cfg, threadCount)
			return GetVSArgs(prj.workspace.name, cfg.name, target, threadCount, false)
		end, false)
end

function m.vscode_tasks_build_all(wks)
	return GenerateTasks(p.workspace.eachconfig(wks), #p.oven.bakeWorkspace(wks).configs,
		function(cfg)
			return string.format("Build All (%s)", cfg.name)
		end,
		function(sys, action, cfgName, threadCount)
			return GetCompileCommand(sys, action, cfgName, nil, threadCount, true)
		end,
		function(cfg, threadCount)
			return GetVSArgs(wks.name, cfg.name, nil, threadCount, true)
		end, true)
end
