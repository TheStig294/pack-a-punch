local UPGRADE = {}
UPGRADE.id = "bfbeenade"
UPGRADE.class = "weapon_ttt_beenade"
UPGRADE.name = "BFBeenade"
UPGRADE.desc = "Spawns invincible big bees!"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldDrawWorldModel = SWEP.DrawWorldModel

    function SWEP:DrawWorldModel()
        self:PAPOldDrawWorldModel()
        self.ModelEntity:SetMaterial(TTTPAP.camo)
    end

    SWEP.PAPOldViewModelDrawn = SWEP.ViewModelDrawn

    function SWEP:ViewModelDrawn()
        self:PAPOldViewModelDrawn()
        local owner = self:GetOwner()

        if IsValid(owner) and owner == LocalPlayer() then
            self.ModelEntity:SetMaterial(TTTPAP.camo)
        end
    end

    function SWEP:GetGrenadeName()
        return "ttt_pap_bfbeenade_proj"
    end

    -- BFBs cannot take damage
    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if IsValid(ent) and ent.PAPBfbnade then return true end
    end)
end

TTTPAP:Register(UPGRADE)