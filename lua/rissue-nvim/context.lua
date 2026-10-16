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

local context = {}

local config = require("rissue-nvim.config")

--- A list of env from various cwd (used on cwd env caching)
---@type table<string, table>
local envs = {}

---@param cwd string
---@param env_name string
---@return string?
local function get_env(cwd, env_name)
  local env = os.getenv(env_name)
  if env then
    return env
  end

  --- custom .env loader
  if not envs[cwd] then
    local env_mod = require("rissue.env")
    env_mod.setup(
      vim.tbl_get(config.settings, "core", "env_file") or ".env",
      cwd
    )
    envs[cwd] = vim.deepcopy(env_mod.env)
  end

  return envs[cwd][env_name]
end

---@param cwd string
---@return string? result
---@return string? err_msg
local function get_git_remote_url(cwd)
  local remote_name = get_env(cwd, "REMOTE_NAME") or config.settings.remote_name
  local result = vim
    .system({
      "git",
      "remote",
      "get-url",
      remote_name,
    }, { text = true })
    :wait()

  if result.code == 0 then
    return result.stdout
  end
  return nil, result.stderr
end

---@return rissue-nvim.Context
---@return string[]? err_msg
function context.get_environment()
  local err_msgs = {}
  local cwd = vim.fn.getcwd()
  local remote_url, remote_err = get_git_remote_url(cwd)
  if remote_err then
    err_msgs[#err_msgs + 1] = "Failed to get git remote: " .. remote_err
  end

  local provider ---@type rissue.ProviderInfo?
  if remote_url then
    local rissue_ok, rissue = pcall(require, "rissue")
    if rissue_ok and rissue then
      local provider_err
      provider, provider_err = rissue.get_provider_info(remote_url)
      if provider_err then
        err_msgs[#err_msgs + 1] = provider_err
      end
    else
      err_msgs[#err_msgs + 1] = rissue
    end
  end

  ---@type rissue-nvim.Context
  local result = {
    cwd = cwd,
    url = remote_url,
    provider_info = provider,
  }

  return result, #err_msgs > 0 and err_msgs or nil
end

return context
