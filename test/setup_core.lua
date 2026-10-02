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
    print(err)
    return false
  end

  local name = vim.uv.fs_scandir_next(req)
  if name then
    return true
  end

  return false
end

local installed_path = os.getenv("CORE_PATH")
if not (installed_path and is_dir_non_empty(installed_path)) then
  installed_path = ".tmp/rissue"
  vim.fn.mkdir(installed_path, "p")
  if not is_dir_non_empty(installed_path) then
    print("git clone rissue.lua to ./.tmp folder")
    vim.fn.system({
      "git",
      "clone",
      "--depth=1",
      "https://github.com/flamfrosticboio/rissue.lua",
      installed_path,
    })
  end
end

vim.opt.rtp:append(installed_path)
