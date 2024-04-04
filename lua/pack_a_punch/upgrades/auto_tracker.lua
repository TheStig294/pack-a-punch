local UPGRADE = {}
UPGRADE.id = "auto_tracker"
UPGRADE.class = "weapon_ttt_phy_tracker"
UPGRADE.name = "Auto Tracker"
UPGRADE.desc = "Auto-tracks all alive players!"

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    local owner = SWEP:GetOwner()
    if not IsValid(owner) then return end
    local plys = player.GetAll()
    table.Shuffle(plys)

    for _, ply in ipairs(plys) do
        if IsPlayer(ply) and ply:Alive() and not ply:IsSpec() and not GAMEMODE.PHYSICIAN:IsPlayerBeingTracked(owner, ply) then
            GAMEMODE.PHYSICIAN:AddNewTrackedPlayer(owner, ply)
        end
    end

    owner:EmitSound("buttons/combine_button7.wav")
end

TTTPAP:Register(UPGRADE)