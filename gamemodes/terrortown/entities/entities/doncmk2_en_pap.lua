AddCSLuaFile()
ENT.Base = "doncmk2_en"
ENT.Type = "anim"
ENT.PrintName = "Big Boi Donconnon"

function ENT:Initialize()
    self.BaseClass.Initialize(self)
    -- PAP camo, no sound on shoot
    self:SetMaterial(TTTPAP.camo)

    if SERVER then
        self.Trail = util.SpriteTrail(self, 0, Color(255, 0, 0), false, 500, 0, 3, 1 / 100 * 0.5, "sprites/combineball_trail_red_1") -- New red trail
        -- Sound is heard everywhere and is louder
        self:EmitSound(self.Sound, 0)

        -- Leaves a trail of fire
        timer.Create("TTTPAPDonconnonFireTrail" .. self:EntIndex(), 1, 10, function()
            if not IsValid(self) then
                timer.Remove("TTTPAPDonconnonFireTrail")

                return
            end

            local tr = util.QuickTrace(self:GetPos(), Vector(0, 0, -1))
            -- Place the fire slightly ahead of the donconnon as the fire takes a second to spawn
            local forward = self:GetForward() * 300
            StartFires(self:GetPos() + forward, tr, 2, 5, false, self:GetOwner())
        end)
    end
end

if SERVER then
    function ENT:OnRemove()
        -- Always play a larger explosion sound
        self:EmitSound("ambient/explosions/explode_3.wav")
        local explode = ents.Create("env_explosion")
        explode:SetPos(self:GetPos())
        explode:SetOwner(self:GetOwner())
        explode:SetKeyValue("iMagnitude", 550)
        -- 100 extra explosion range
        explode:SetKeyValue("iRadiusOverride", 550)
        explode:Spawn()
        explode:Fire("Explode", 0, 0)
        -- Leaves a bunch of fire on exploding
        local tr = util.QuickTrace(self:GetPos(), Vector(0, 0, -1))
        StartFires(self:GetPos(), tr, 20, 40, false, self:GetOwner())
        timer.Remove("TTTPAPDonconnonFireTrail")
    end
end