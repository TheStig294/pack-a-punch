local UPGRADE = {}
UPGRADE.id = "guaranteed_defib"
UPGRADE.class = "weapon_vadim_defib"
UPGRADE.name = "Guaranteed Defib"
UPGRADE.desc = "Always guaranteed to work!"

function UPGRADE:Apply(SWEP)
    if CLIENT then return end

    function SWEP:PrimaryAttack()
        if self:GetState() ~= 0 then return end
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        local owner = self:GetOwner()
        local tr = owner:GetEyeTrace(MASK_SHOT_HULL)
        if tr.HitPos:Distance(owner:GetPos()) > GetConVar("ttt_defib_maxdist"):GetInt() then return end
        if GetRoundState() ~= ROUND_ACTIVE then return end
        local ent = tr.Entity

        if IsValid(ent) and ent:GetClass() == "prop_ragdoll" and CORPSE.GetPlayerNick(ent, false) then
            self.Location = self:FindRespawnLocation()

            if not self.Location then
                self.Location = owner:GetPos()
            end

            self:Begin(ent, tr.PhysicsBone)
        end
    end

    function SWEP:Defib()
        sound.Play("ambient/energy/zap7.wav", self.Target:GetPos(), 75, math.random(95, 105), 1)
        if not IsFirstTimePredicted() then return end
        self:DoRespawn(self.Target)
        self:Reset()
    end
end

TTTPAP:Register(UPGRADE)