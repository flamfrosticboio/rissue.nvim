# RIssue.nvim

A nvim integration of [flamfrosticboio/rissue.lua](https://github.com/flamfrosticboio/rissue.lua).

## Documentation

Browse in the [docs folder](./docs) for documentation.

## Setup

With lazy:

```lua
return {
  "flamfrosticboio/rissue.nvim",
  dependencies = {
    {"flamfrosticboio/rissue.lua", opts = {}},
  },
  opts = {}
}
```

````lua
return {
  "flamfrosticboio/rissue.nvim",
  dependencies = {
    "flamfrosticboio/rissue.lua",
    -- but no way to initialize it or we can use rissue.nvim to do this
  },
  opts = {
    -- settings from rissue.lua is reflected here
  }
}
```
## Developing

Install [mise](https://github.com/jdx/mise) from your preferred ways and run:

```bash
mise setup
````
