local UPGRADE = {}
UPGRADE.id = "possum_disguiser"
UPGRADE.class = "weapon_psm_disguiser"
UPGRADE.name = "Possum Disguise"
UPGRADE.desc = "Increased disguiser capacity"
local possumModel = "models/tsbb/animals/possum.mdl"
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
    self:SetClip(SWEP, ammoMultCvar:GetFloat() * 100)

    if possumInstalled then
        self:AddHook("PlayerPostThink", function(ply)
            local ragdoll = ply.possumRagdoll

            -- Set model on disguise
            if IsValid(ragdoll) and not IsValid(ragdoll.PAPPossumModel) and ply:HasWeapon(self.class) and self:IsUpgraded(ply:GetWeapon(self.class)) then
                ragdoll:SetNoDraw(true)
                local possum = ents.Create("prop_physics")
                local pos = ragdoll:GetPos()
                local ang = ragdoll:GetAngles()
                possum:SetModel(possumModel)
                possum:SetParent(ragdoll)
                possum:SetPos(pos)
                possum:SetAngles(ang)
                possum:Spawn()
                possum:PhysWake()
                ragdoll.PAPPossumModel = possum
            end
        end)
    end
end

TTTPAP:Register(UPGRADE)