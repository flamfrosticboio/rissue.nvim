-- RIssue.nvim - Nvim integration for flamfrosticboio/rissue.lua
-- Copyright (C) 2026  flamfrosticboio
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

vim.opt.rtp:prepend(".")

local function is_dir_non_empty(path)
  local req, err = vim.uv.fs_scandir(path)
  if not req then
    print("Warning: " .. err)
    return false
  end

  local name = vim.uv.fs_scandir_next(req)
  if name then
    return true
  end

  return false
end

---@param url string
---@param target string
---@param branch string?
local function git_clone(url, target, branch)
  print(
    "Running git clone "
      .. url
      .. ((branch and " on branch " .. branch) or "")
      .. " > "
      .. target
  )
  local cmd = {
    "git",
    "clone",
    "--depth=1",
  }

  if branch then
    cmd[#cmd + 1] = "--branch"
    cmd[#cmd + 1] = branch
  end

  cmd[#cmd + 1] = url
  cmd[#cmd + 1] = target

  local result =
    vim.system(cmd, { text = true, env = { GIT_TERMINAL_PROMPT = 0 } }):wait()
  if result.code ~= 0 then
    error(
      "failed to git clone: "
        .. (result.stderr or "~nil")
        .. "\nstdout:"
        .. (result.stdout or "~nil"),
      0
    )
  end

  print("git clone was complete")
end

-- https://github.com/folke/snacks.nvim

local rissue_version = "v0.1"

local installed_path = os.getenv("CORE_PATH")
if not (installed_path and is_dir_non_empty(installed_path)) then
  installed_path = ".tmp/rissue"
  vim.fn.mkdir(installed_path, "p")
  if not is_dir_non_empty(installed_path) then
    git_clone(
      "https://github.com/flamfrosticboio/rissue.lua",
      installed_path,
      rissue_version
    )
  end
end

--- follows format: { name, url, branch }
--- env_name check is transformed with name:upper()
---@type { [1]: string, [2]: string, [3]: string? }[]
local other_dependencies = {
  { "snacks", "https://github.com/folke/snacks.nvim", "stable" },
}

local install_all = os.getenv("INSTALL_ALL") == "true"
for _, dependencies in ipairs(other_dependencies) do
  local env = dependencies[1]:upper()
  local path = ".tmp/" .. dependencies[1]
  if
    not is_dir_non_empty(path) and (install_all or os.getenv(env) == "true")
  then
    git_clone(dependencies[2], ".tmp/" .. dependencies[1], dependencies[3])
  end
end

vim.opt.rtp:append(installed_path)
