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

local chunk, load_err = loadfile("test/setup_core.lua")
if not chunk then
  error(load_err)
end

chunk()

vim.opt.rtp:prepend(".")
local plenary_dir = ".tmp/plenary.nvim"

if vim.fn.isdirectory(plenary_dir) == 0 then
  vim.fn.system({
    "git",
    "clone",
    "--depth=1",
    "https://github.com/nvim-lua/plenary.nvim",
    plenary_dir,
  })
end

vim.opt.rtp:append(plenary_dir)
