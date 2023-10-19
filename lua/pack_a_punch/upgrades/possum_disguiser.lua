local UPGRADE = {}
UPGRADE.id = "possum_disguiser"
UPGRADE.class = "weapon_psm_disguiser"
UPGRADE.name = "Possum Disguise"
UPGRADE.desc = "Increased disguiser capacity"
local possumModel = "models/TSBB/Animals/Possum.mdl"
local possumInstalled = util.IsValidModel(possumModel)

if possumInstalled then
    UPGRADE.desc = UPGRADE.desc .. "\nBecome a possum while disguised!"
end

UPGRADE.convars = {
    {
        name = "pap_possum_disguiser_ammo_mult",
        type = "float",
        decimals = 1
    }
}

local ammoMultCvar = CreateConVar("pap_possum_disguiser_ammo_mult", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Disguiser capacity multiplier", 1, 5)

function UPGRADE:Apply(SWEP)
    -- Ammo increase
    local ammo = ammoMultCvar:GetFloat() * 100
    SWEP.Primary.ClipSize = ammo
    SWEP.Primary.ClipMax = ammo

    if possumInstalled then
        self:AddHook("PlayerPostThink", function(ply)
            -- Set model on disguise
            if IsValid(ply.possumRagdoll) and ply:HasWeapon(self.class) and ply:GetWeapon(self.class).PAPUpgrade then
                ply.possumRagdoll:SetModel(possumModel)
            end
        end)
    end
end

TTTPAP:Register(UPGRADE)