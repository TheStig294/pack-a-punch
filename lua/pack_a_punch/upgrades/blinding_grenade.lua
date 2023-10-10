local UPGRADE = {}
UPGRADE.id = "blinding_grenade"
UPGRADE.class = "weapon_ttt_flashbang"
UPGRADE.name = "Blinding Grenade"
UPGRADE.desc = "Permenantly blinds victims,\nbut they can see player outlines"

function UPGRADE:Apply(SWEP)
    if SERVER then
        function SWEP:GetGrenadeName()
            return "ttt_pap_blinding_grenade"
        end
    end
end

TTTPAP:Register(UPGRADE)