local UPGRADE = {}
UPGRADE.id = "ninja_bomb"
UPGRADE.class = "weapon_ttt_smokegrenade"
UPGRADE.name = "Ninja bomb"
UPGRADE.desc = "Very large smoke cloud"

function UPGRADE:Apply(SWEP)
    if SERVER then
        function SWEP:GetGrenadeName()
            return "ttt_pap_ninja_bomb_nade"
        end
    end
end

TTTPAP:Register(UPGRADE)