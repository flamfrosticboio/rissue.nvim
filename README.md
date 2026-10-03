# RIssue.nvim

A nvim integration of [flamfrosticboio/rissue.lua](https://github.com/flamfrosticboio/rissue.lua).

> [!NOTE]
> Currently, the only supported integration is snacks, but there will be more
> to come.

## Documentation

Browse in the [docs folder](./docs) for documentation.

## Setup

With lazy:

```lua
return {
  "flamfrosticboio/rissue.nvim",
  dependencies = {
    "flamfrosticboio/rissue.lua",
    -- if using snacks
    "folke/snacks.nvim"
  },
  opts = {
    -- Your custom settings. Read more on ./docs/setup.md
  }
}
```

## Developing

Install [mise](https://github.com/jdx/mise) from your preferred ways and run:

```bash
mise setup
```

## License

This project uses the [GPLv3 license](./LICENSE)
