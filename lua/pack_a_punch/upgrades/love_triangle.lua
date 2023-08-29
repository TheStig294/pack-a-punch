local UPGRADE = {}
UPGRADE.id = "love_triangle"
UPGRADE.class = "weapon_cup_bow"
UPGRADE.name = "Love Triangle"
UPGRADE.desc = "You can make 3 people fall in love!"

function UPGRADE:Apply(SWEP)
    function SWEP:Think()
        local holdType = self.HoldTypeTranslate[self.dt.WepState]

        if holdType ~= self:GetHoldType() then
            self:SetHoldType(holdType)
        end

        if self:GetNextPrimaryFire() >= CurTime() then return end
        local owner = self:GetOwner()

        if self.dt.WepState == self.STATE_PULLED then
            if owner:KeyDown(IN_RELOAD) then
                self.dt.WepState = self.STATE_NOCKED
                self:RunActivity(ACT_VM_RELEASE)
            elseif not owner:KeyDown(IN_ATTACK) then
                self.dt.WepState = self.STATE_RELEASE
                self:RunActivity(ACT_VM_PRIMARYATTACK)

                if SERVER then
                    local ang = owner:GetAimVector():Angle()
                    local pos = owner:EyePos() + ang:Up() * -7 + ang:Forward() * -4

                    if not owner:KeyDown(IN_ATTACK2) then
                        pos = pos + ang:Right() * 1.5
                    end

                    local charge = self:GetNextSecondaryFire()
                    charge = math.Clamp(CurTime() - charge, 0, 1)
                    local arrow = ents.Create("ttt_cup_arrow_pap")
                    arrow:SetOwner(owner)
                    arrow:SetPos(pos)
                    arrow:SetAngles(ang)
                    arrow:Spawn()
                    arrow:Activate()
                    arrow:SetVelocity(ang:Forward() * 2500 * charge)
                    arrow:SetMaterial(TTTPAP.camo)
                    arrow.Weapon = self
                end
            end
        elseif self.dt.WepState == self.STATE_RELEASE then
            self.dt.WepState = self.STATE_NOCKED
            self:RunActivity(ACT_VM_LOWERED_TO_IDLE)
        elseif self.dt.WepState == self.STATE_NOCKED then
            if owner:KeyDown(IN_ATTACK) and not owner:KeyDown(IN_RELOAD) then
                self.dt.WepState = self.STATE_PULLED
                self:RunActivity(ACT_VM_PULLBACK)
                self:SetNextSecondaryFire(CurTime())
            end
        end

        if IsValid(owner) and owner:GetNWString("TTTCupidTarget3", "") ~= "" then
            self:Remove()
        end
    end

    -- Kills all players in the "Love triangle" when one dies
    self:AddHook("PostPlayerDeath", function(deadPly)
        local plys = {SWEP.Target1, SWEP.Target2, SWEP.Target3}

        local killPlys = false

        for _, ply in ipairs(plys) do
            if IsValid(ply) and ply == deadPly then
                killPlys = true
                break
            end
        end

        if killPlys then
            for _, ply in ipairs(plys) do
                if IsValid(ply) and ply:Alive() and not ply:IsSpec() then
                    ply:Kill()
                end
            end
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply:SetNWString("TTTCupidTarget3", "")
    end
end

TTTPAP:Register(UPGRADE)