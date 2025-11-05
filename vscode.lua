--
-- Name:        vscode.lua
-- Purpose:     Define the vscode action(s).
-- Author:      Ryan Pusztai
-- Modified by: Andrea Zanellato
--              Andrew Gough
--              Manu Evans
--              Jason Perkins
--              Yehonatan Ballas
--              Jan "GamesTrap" Schürkamp
-- Created:     2013/05/06
-- Updated:     2025/11/04
-- Copyright:   (c) 2008-2020 Jason Perkins and the Premake project
--              (c) 2022-2025 Jan "GamesTrap" Schürkamp
--

local p = premake

p.modules.vscode = {}

local vscode = p.modules.vscode

local function GetCProjects(wks)
    local list = {}

    for prj in p.workspace.eachproject(wks) do
        if p.project.isc(prj) or p.project.iscpp(prj) then
            list[#list + 1] = prj
        end
    end

    return list
end

local function WriteFile(path, contentWriter)
    local file = io.open(path, "w")
    if not file then
        return
    end

    contentWriter(file)
    file:close()
end

-- Create .code-workspace file if it doesnt already exist
local function GenerateVSCodeWorkspaceFile(wks)
    local path = string.format("%s/%s.code-workspace", wks.location, wks.name)
    if os.isfile(path) then
        return
    end

    WriteFile(path, function(f)
        f:write([[
{
    "folders":
    [
        {
            "path": "."
        }
    ]
}
]])
    end)
end

local function EnsureVSCodeDir(wks)
    local dir = string.format("%s/.vscode", wks.location)
    os.mkdir(dir)
end

-- Create tasks.json file
local function GenerateTasksFile(wks, cProjects)
    EnsureVSCodeDir(wks)
    local path = string.format("%s/.vscode/tasks.json", wks.location)

    WriteFile(path, function(f)
        f:write('{\n\t"version": "2.0.0",\n\t"tasks":\n\t[\n')

        for _, prj in ipairs(cProjects) do
            vscode.project.vscode_tasks(prj, f)
        end

        if #cProjects > 0 then
            vscode.project.vscode_tasks_build_all(wks, f)
        end

        f:write('\t]\n}\n')
    end)
end

-- Create launch.json file
local function GenerateLaunchFile(wks, cProjects)
    EnsureVSCodeDir(wks)
    local path = string.format("%s/.vscode/launch.json", wks.location)

    WriteFile(path, function(f)
        f:write('{\n\t"version": "2.0.0",\n\t"configurations":\n\t[\n')

        for _, prj in ipairs(cProjects) do
            vscode.project.vscode_launch(prj, f)
        end

        f:write('\t]\n}\n')
    end)
end

-- Create c_cpp_properties.json file
local function GenerateCCppPropertiesFile(wks, cProjects)
    if #cProjects == 0 then
        return
    end

    EnsureVSCodeDir(wks)
    local path = string.format("%s/.vscode/c_cpp_properties.json", wks.location)

    WriteFile(path, function(f)
        f:write('{\n\t"version": 4,\n\t"configurations":\n\t[\n')

        for _, prj in ipairs(cProjects) do
            vscode.project.vscode_c_cpp_properties(prj, f)
        end

        f:write('\t]\n}\n')
    end)
end

function vscode.generateWorkspace(wks)
    local cProjects = GetCProjects(wks)

    GenerateVSCodeWorkspaceFile(wks)
    GenerateTasksFile(wks, cProjects)
    GenerateLaunchFile(wks, cProjects)
    GenerateCCppPropertiesFile(wks, cProjects)
end

include("vscode_project.lua")
include("_preload.lua")

return vscode
