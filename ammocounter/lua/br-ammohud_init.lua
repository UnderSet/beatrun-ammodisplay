--[[--------------------------------------------------------------------
    Manual initialization script.
    Run if playing on a server that allows sv_allowcslua.

    Yeah this message is essentially taken from H0L-D4's
    source (https://github.com/DyaMetR/holohud) I won't argue with that.
]]----------------------------------------------------------------------

if SERVER then return end -- Don't run on servers. Obviously.

include('autorun/ammocounter.lua') -- Initialize the ammo display.