# gm_express_bindings

Adapts existing addons to use [`gm_express`](https://github.com/CFC-Servers/gm_express) to network large chunks of data

## Requirements
- Obviously, requires [`gm_express`](https://github.com/CFC-Servers/gm_express)

## Modules
All modules are enabled/disabled with convars _(should update immediately for both cl/sv - ideally seamless, realistically prone to problems)_.

Modules don't load if the relevant addon isn't installed 👍

<br>


| Addon                                                 | Description                            | Convar                             |
|-------------------------------------------------------|----------------------------------------|------------------------------------|
| [PAC3](https://github.com/CapsAdmin/pac3)             | Transmits outfits                      | `express_bindings_enable_pac3`     |
| [StarfallEx](https://github.com/thegrb93/StarfallEx)  | Transmits the Starfall code itself     | `express_bindings_enable_starfall` |
| [Prop2Mesh](https://github.com/shadowscion/Prop2Mesh) | Intelligently transmits all P2M meshes | `express_bindings_enable_p2m`      |

> [!WARNING]
> Because CFC (and many other servers) use a fork of PAC3 _(pre combat update)_, there is no guarantee that this will work with the latest version of PAC3


<br>

## Adding a Binding

If you want to add a binding for some other addon and PR it to this repo, please go ahead!

The existing examples should be pretty clear, but just in case it's useful I roughtly outlined how to set it up below

<br>

First, make a new directory in `lua/gm_express_bindings/`

Then, make a `sh_init.lua` in the following format:
```lua
AddCSLuaFile()

-- Should it default to enabled?
local Module = { default = true }

-- Include the relevant files, which return functions. Immediately call them and give the Module object
if SERVER then
    AddCSLuaFile( "cl_init.lua" )
    include( "sv_init.lua" )( Module )
else
    include( "cl_init.lua" )( Module )
end

-- `IsValid` determines if the Module is allowed to load (e.g. does the addon exist)
function Module:IsValid()
    return prop2mesh ~= nil
end

-- Register the module with the internal name (used to generate the convars)
ExpressBindings.RegisterModule( "p2m", Module )
```

Your server and client files should both probably follow the following format:
```lua
-- Be sure to return a function that takes a Module object
return function( Module )
    function Module.Enable()
        -- When the Module is enabled
        -- Often times means wrapping functions that the addon uses to transmit data
    end

    function Module.Disable()
        -- What to do when the module is diabled
        -- (Probably unwrap whatever functions you wraped in .Enable)
    end
end
```

You can obviously create the `Module` table however you want, it just needs the following entries:
- `default: boolean` (whether or not to enable the module by default)
- `Enable: function`
- `Disable: function`

As long as you call `ExpressBindings.RegisterModule` with a string and a `Module` table, you're good to go.
