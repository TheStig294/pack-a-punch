local UPGRADE = {}
UPGRADE.id = "forever_fire_nade"
UPGRADE.class = "weapon_zm_molotov"
UPGRADE.name = "Forever Fire-Nade"
UPGRADE.desc = "Larger explosion, fire lasts a very long time!"

function UPGRADE:Apply(SWEP)
    if SERVER then
        function SWEP:GetGrenadeName()
            return "ttt_pap_forever_fire_nade"
        end
    end
end

TTTPAP:Register(UPGRADE)