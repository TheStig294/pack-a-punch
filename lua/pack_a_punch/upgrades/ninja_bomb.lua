local UPGRADE = {}
UPGRADE.id = "ninja_bomb"
UPGRADE.class = "weapon_ttt_smokegrenade"
UPGRADE.name = "Ninja bomb"
UPGRADE.desc = "Very large smoke cloud"

function UPGRADE:Apply(SWEP)
    if SERVER then
        function SWEP:GetGrenadeName()
            return "ttt_smokegrenade_proj_pap"
        end
    end
end

TTTPAP:Register(UPGRADE)