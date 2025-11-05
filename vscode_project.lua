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

function m.getcorecount()
	local cores = 0

	-- Check command-line arguments for threads ovveride
	for i, arg in ipairs(_ARGS) do
		if (arg == "--threads") or (arg == "-t") then
			cores = tonumber(_ARGS[i + 1])
		end
	end

	if cores == 0 then
		if os.host() == "windows" then
			local result, errorcode = os.outputof("wmic cpu get NumberOfCores")
			for core in result:gmatch("%d+") do
				cores = cores + core
			end
		else
			local result, errorcode = os.outputof("nproc")
			cores = tonumber(result)
		end
	end

	if cores <= 0 then
		cores = 1
	end

	return cores
end

function m.getlinuxcompilecommand(cfgName, prjName, coreCount)
	if(_OPTIONS["action"]) then
		if(_OPTIONS["action"] == "make") then
			return string.format('clear && time make config=%s %s -j%s', string.lower(cfgName), prjName, coreCount)
		elseif (_OPTIONS["action"] == "ninja") then
			return string.format('clear && time ninja %s_%s -j%s', prjName, cfgName, coreCount)
		end
	end
end

function m.getwindowscompilecommand(cfgName, prjName, coreCount)
	if(_OPTIONS["action"]) then
		if(_OPTIONS["action"] == "vs") then
			return 'cls && msbuild'
		elseif(_OPTIONS["action"] == "make") then
			return string.format('cls && make config=%s %s -j%s', string.lower(cfgName), prjName, coreCount)
		elseif (_OPTIONS["action"] == "ninja") then
			return string.format('cls && ninja %s_%s -j%s', prjName, cfgName, coreCount)
		end
	end
end

function m.getwindowscompileargs(wksName, cfgName, target, coreCount)
	args = {}

	if(_OPTIONS["action"] and _OPTIONS["action"] == "vs") then
		table.insert(args, string.format('/m:%s', coreCount))
		table.insert(args, string.format('${workspaceRoot}/%s.sln', wksName))
		table.insert(args, string.format('/p:Configuration=%s', cfgName))
		table.insert(args, string.format('/t:%s', target))
	end

	return args
end

function m.vscode_tasks(prj, tasksFile)
	local output = ""

	for cfg in project.eachconfig(prj) do
		local buildName = "Build " .. prj.name .. " (" .. cfg.name .. ")"
		local target = path.translate(path.getrelative(prj.workspace.location, prj.location))

		output = output .. '\t\t{\n'
		output = output .. string.format('\t\t\t"label": "%s",\n', buildName)
		output = output .. '\t\t\t"type": "shell",\n'
		if os.target() ~= "windows" then
			output = output .. '\t\t\t"linux":\n'
			output = output .. '\t\t\t{\n'
			output = output .. string.format('\t\t\t\t"command": "%s",\n', m.getlinuxcompilecommand(cfg.name, prj.name, m.getcorecount()))
			output = output .. '\t\t\t\t"problemMatcher": "$gcc",\n'
			output = output .. '\t\t\t},\n'
		elseif os.target() == "windows" then
			output = output .. '\t\t\t"windows":\n'
			output = output .. '\t\t\t{\n'
			output = output .. string.format('\t\t\t\t"command": "%s",\n', m.getwindowscompilecommand(cfg.name, prj.name, m.getcorecount()))
			output = output .. '\t\t\t\t"args":\n'
			output = output .. '\t\t\t\t[\n'
			local winCompileArgs = m.getwindowscompileargs(prj.workspace.name, cfg.name, target, m.getcorecount())
			if winCompileArgs then
				for arg in m.getwindowscompileargs(prj.workspace.name, cfg.name, target, m.getcorecount()) do
					output = output .. string.format('\t\t\t\t\t"%s",\n', arg)
				end
			end
			output = output .. '\t\t\t\t],\n'
			output = output .. '\t\t\t\t"problemMatcher": "$msCompile",\n'
			output = output .. '\t\t\t},\n'
		end
		output = output .. '\t\t\t"group":\n'
		output = output .. '\t\t\t{\n'
		output = output .. '\t\t\t\t"kind": "build",\n'
		output = output .. '\t\t\t},\n'
		output = output .. '\t\t},\n'
	end

	tasksFile:write(output)
end

function m.getlinuxcompileallcommand(cfgName, coreCount)
	if(_OPTIONS["action"]) then
		if(_OPTIONS["action"] == "make") then
			return string.format('clear && time make config=%s all -j%s', string.lower(cfgName), coreCount)
		elseif (_OPTIONS["action"] == "ninja") then
			return string.format('clear && time ninja %s -j%s', cfgName, coreCount)
		end
	end
end

function m.getwindowscompileallcommand(cfgName, coreCount)
	if(_OPTIONS["action"]) then
		if(_OPTIONS["action"] == "vs") then
			return 'cls && msbuild'
		elseif(_OPTIONS["action"] == "make") then
			return string.format('cls && make config=%s all -j%s', string.lower(cfgName), coreCount)
		elseif (_OPTIONS["action"] == "ninja") then
			return string.format('cls && ninja %s -j%s', cfgName, coreCount)
		end
	end
end

function m.getwindowscompileallargs(wksName, cfgName, coreCount)
	args = {}

	if(_OPTIONS["action"] and _OPTIONS["action"] == "vs") then
		table.insert(args, string.format('/m:%s', coreCount))
		table.insert(args, string.format('${workspaceRoot}/%s.sln', wksName))
		table.insert(args, string.format('/p:Configuration=%s', cfgName))
		table.insert(args, '/t:Build')
	end

	return args
end

function m.vscode_tasks_build_all(wks, tasksFile)
	local output = ""

	for cfg in p.workspace.eachconfig(wks) do
		local buildName = "Build All (" .. cfg.name .. ")"

		output = output .. '\t\t{\n'
		output = output .. string.format('\t\t\t"label": "%s",\n', buildName)
		output = output .. '\t\t\t"type": "shell",\n'
		if os.target() ~= "windows" then
			output = output .. '\t\t\t"linux":\n'
			output = output .. '\t\t\t{\n'
			output = output .. string.format('\t\t\t\t"command": "%s",\n', m.getlinuxcompileallcommand(cfg.name, m.getcorecount()))
			output = output .. '\t\t\t\t"problemMatcher": "$gcc",\n'
			output = output .. '\t\t\t},\n'
		elseif os.target() == "windows" then
			output = output .. '\t\t\t"windows":\n'
			output = output .. '\t\t\t{\n'
			output = output .. string.format('\t\t\t\t"command": "%s",\n', m.getwindowscompileallcommand(cfg.name, m.getcorecount()))
			output = output .. '\t\t\t\t"args":\n'
			output = output .. '\t\t\t\t[\n'
			local winCompileArgs = m.getwindowscompileallargs(wks.name, cfg.name, m.getcorecount())
			if winCompileArgs then
				for arg in winCompileArgs do
					output = output .. string.format('\t\t\t\t\t"%s",\n', arg)
				end
			end
			output = output .. '\t\t\t\t],\n'
			output = output .. '\t\t\t\t"problemMatcher": "$msCompile",\n'
			output = output .. '\t\t\t},\n'
		end
		output = output .. '\t\t\t"group":\n'
		output = output .. '\t\t\t{\n'
		output = output .. '\t\t\t\t"kind": "build",\n'
		output = output .. '\t\t\t},\n'
		output = output .. '\t\t},\n'
	end

	tasksFile:write(output)
end

function m.vscode_launch(prj, launchFile)
	local output = ""

	for cfg in project.eachconfig(prj) do
		if cfg.kind == "ConsoleApp" or cfg.kind == "WindowedApp" then --Ignore non executable configuration(s) in launch.json
			local buildName = "Build " .. prj.name .. " (" .. cfg.name .. ")"
			local target = path.getrelative(prj.workspace.location, prj.location)
			local gdbPath = ""
			if os.host() == "linux" then
				gdbPath = os.outputof("which gdb")
			end
			local programPath = path.getrelative(prj.workspace.location, cfg.buildtarget.abspath)

			output = output .. '\t\t{\n'
			output = output .. string.format('\t\t\t"name": "Run %s (%s)",\n', prj.name, cfg.name)
			output = output .. '\t\t\t"request": "launch",\n'
			output = output .. '\t\t\t"type": "cppdbg",\n'
			output = output .. string.format('\t\t\t"program": "${workspaceRoot}/%s",\n', programPath)
			if os.target() ~= "windows" then
				output = output .. '\t\t\t"linux":\n'
				output = output .. '\t\t\t{\n'
				output = output .. string.format('\t\t\t\t"name": "Run %s (%s)",\n', prj.name, cfg.name)
				output = output .. '\t\t\t\t"type": "cppdbg",\n'
				output = output .. '\t\t\t\t"request": "launch",\n'
				output = output .. string.format('\t\t\t\t"program": "${workspaceRoot}/%s",\n', programPath)
				output = output .. '\t\t\t\t"externalConsole": true,\n'
				output = output .. string.format('\t\t\t\t"miDebuggerPath": "%s",\n', gdbPath)
				output = output .. '\t\t\t\t"MIMode": "gdb",\n'
				output = output .. '\t\t\t\t"setupCommands":\n'
				output = output .. '\t\t\t\t[\n'
				output = output .. '\t\t\t\t\t{\n'
				output = output .. '\t\t\t\t\t\t"text": "-enable-pretty-printing",\n'
				output = output .. '\t\t\t\t\t\t"description": "enable pretty printing",\n'
				output = output .. '\t\t\t\t\t\t"ignoreFailures": true,\n'
				output = output .. '\t\t\t\t\t},\n'
				output = output .. '\t\t\t\t],\n'
				output = output .. '\t\t\t},\n'
			elseif os.target() == "windows" then
				output = output .. '\t\t\t"windows":\n'
				output = output .. '\t\t\t{\n'
				output = output .. string.format('\t\t\t\t"name": "Run %s (%s)",\n', prj.name, cfg.name)
				output = output .. '\t\t\t\t"console": "externalTerminal",\n'
				output = output .. '\t\t\t\t"type": "cppvsdbg",\n'
				output = output .. '\t\t\t\t"request": "launch",\n'
				output = output .. string.format('\t\t\t\t"program": "${workspaceRoot}/%s",\n', programPath)
				output = output .. '\t\t\t},\n'
			end
			output = output .. '\t\t\t"args": [],\n'
			output = output .. '\t\t\t"stopAtEntry": false,\n'
			output = output .. string.format('\t\t\t"cwd": "${workspaceFolder}/%s",\n', target)
			output = output .. '\t\t\t"environment": [],\n'
			output = output .. string.format('\t\t\t"preLaunchTask": "Build %s (%s)",\n', prj.name, cfg.name)
			output = output .. '\t\t},\n'
		end
	end

	launchFile:write(output)
end

function m.vscode_c_cpp_properties(prj, propsFile)
	local cdialect = "${default}"
	if prj.cdialect then
		cdialect = string.lower(prj.cdialect)
	end

	local cppdialect = "${default}"
	if prj.cppdialect then
		cppdialect = string.lower(prj.cppdialect)
	end

	local output = ""

	for cfg in project.eachconfig(prj) do
		output = output .. '\t\t{\n'
		output = output .. string.format('\t\t\t"name": "%s (%s)",\n', prj.name, cfg.name)
		output = output .. '\t\t\t"includePath":\n'
		output = output .. '\t\t\t[\n'
		output = output .. '\t\t\t\t"${workspaceFolder}/**"'
		if #cfg.includedirs > 0 or #cfg.externalincludedirs > 0 then
			output = output .. ','
		end
		output = output .. '\n'
		for _, includedir in ipairs(cfg.includedirs) do
			output = output .. string.format('\t\t\t\t"%s",\n', includedir)
		end
		for _, includedir in ipairs(cfg.externalincludedirs) do
			output = output .. string.format('\t\t\t\t"%s",\n', includedir)
		end
		if #cfg.includedirs > 0 or #cfg.externalincludedirs > 0 then
			output = output:sub(1, -3) .. '\n'
		end
		output = output .. '\t\t\t],\n'
		output = output .. '\t\t\t"defines":\n'
		output = output .. '\t\t\t[\n'
		for i = 1, #cfg.defines do
			output = output .. string.format('\t\t\t\t"%s",\n', cfg.defines[i]:gsub('"','\\"'))
		end
		if #cfg.defines > 0 then
			output = output:sub(1, -3) .. '\n'
		end
		output = output .. '\t\t\t],\n'
		output = output .. string.format('\t\t\t"cStandard": "%s",\n', cdialect)
		output = output .. string.format('\t\t\t"cppStandard": "%s",\n', cppdialect)
		output = output .. '\t\t\t"intelliSenseMode": "${default}"\n'

		output = output .. '\t\t},\n'
	end

	propsFile:write(output)
end
