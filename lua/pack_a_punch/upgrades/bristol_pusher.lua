local UPGRADE = {}
UPGRADE.id = "bristol_pusher"
UPGRADE.class = "weapon_ttt_confgrenade"
UPGRADE.name = "The Bristol Pusher"
UPGRADE.desc = "Massive push power!"

function UPGRADE:Apply(SWEP)
    if SERVER then
        function SWEP:GetGrenadeName()
            return "ttt_pap_bristol_pusher_nade"
        end
    end
end

TTTPAP:Register(UPGRADE)