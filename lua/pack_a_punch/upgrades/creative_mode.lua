local UPGRADE = {}
UPGRADE.id = "creative_mode"
UPGRADE.class = "minecraft_swep"
UPGRADE.name = "Creative Mode"
UPGRADE.desc = "Greatly increased block placement distance!"

UPGRADE.convars = {
    {
        name = "pap_creative_mode_distance",
        type = "int"
    }
}

local distCvar = CreateConVar("pap_creative_mode_distance", 2400, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Distance blocks can be placed", 1, 5000)

function UPGRADE:Apply(SWEP)
    if SERVER then return end
    local owner = SWEP:GetOwner()
    if not IsValid(owner) or owner ~= LocalPlayer() then return end
    local spawnDistCvar = GetConVar("minecraft_maxspawndist")
    owner.PAPOldMinecraftSWEPDist = spawnDistCvar:GetInt()
    RunConsoleCommand("minecraft_maxspawndist", distCvar:GetInt())
end

function UPGRADE:Reset()
    if SERVER then return end
    local ply = LocalPlayer()

    if ply.PAPOldMinecraftSWEPDist then
        RunConsoleCommand("minecraft_maxspawndist", ply.PAPOldMinecraftSWEPDist or "300")
        ply.PAPOldMinecraftSWEPDist = nil
    end
end

TTTPAP:Register(UPGRADE)