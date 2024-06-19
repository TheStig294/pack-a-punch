local UPGRADE = {}
UPGRADE.id = "blinding_grenade"
UPGRADE.class = "weapon_ttt_flashbang"
UPGRADE.name = "Blinding Grenade"
UPGRADE.desc = "Temporarily blinds victims,\nbut they can see player outlines"

UPGRADE.convars = {
    {
        name = "pap_blinding_grenade_seconds_duration",
        type = "int"
    }
}

CreateConVar("pap_blinding_grenade_seconds_duration", "20", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds the blindness lasts", 1, 60)

function UPGRADE:Apply(SWEP)
    if SERVER then
        function SWEP:GetGrenadeName()
            return "ttt_pap_blinding_grenade"
        end
    end
end

TTTPAP:Register(UPGRADE)