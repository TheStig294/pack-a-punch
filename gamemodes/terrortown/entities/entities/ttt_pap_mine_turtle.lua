AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_mine_turtle"
ENT.HelloSound = Sound("ttt_pack_a_punch/mine_train/i_like_trains.mp3")
ENT.ExplosionSound = Sound("ttt_pack_a_punch/mine_train/train.mp3")
ENT.PrintName = "Train Turtle"

function ENT:Explode(checkActive)
    if IsValid(self) and not self.Exploding then
        if checkActive and not self:IsActive() then return end
        self.Exploding = true
        local pos = self:GetPos()
        local radius = self.BlastRadius
        local damage = self.BlastDamage
        self:EmitSound(self.ExplosionSound, 100)
        local dmg = DamageInfo()
        dmg:SetDamage(damage)
        dmg:SetDamageType(DMG_GENERIC)
        dmg:SetInflictor(self)
        dmg:SetAttacker(self:GetPlacer())
        util.BlastDamageInfo(dmg, pos, radius)
        -- Lift the train up from the ground a bit
        pos.y = pos.y + 500
        pos.z = pos.z + 100
        local train = ents.Create("ttt_pap_mine_train")
        train:SetPos(pos)
        train:Spawn()
        self:Remove()
    end
end

function ENT:UseOverride(activator)
    if IsValid(self) and (not self.Exploding) and IsValid(activator) and activator:IsPlayer() then
        local owner = self:GetPlacer()

        if (self:IsActive() and owner == activator) or (not self:IsActive()) then
            -- check if the user already has a mine turtle
            if activator:HasWeapon("weapon_ttt_mine_turtle") then
                local weapon = activator:GetWeapon("weapon_ttt_mine_turtle")
                weapon:SetClip1(weapon:Clip1() + 1)
            else
                local weapon = activator:Give("weapon_ttt_mine_turtle")
                TTTPAP:ApplyUpgrade(weapon, self.PAPUpgrade)
                weapon:SetClip1(1)
            end

            -- remove the entity
            if activator:HasWeapon("weapon_ttt_mine_turtle") then
                if self:GetPlacer() ~= activator then
                    activator:EmitSound(self.HelloTurtleSound)
                end

                self:Remove()
            else
                LANG.Msg(activator, "mine_turtle_full")
            end
        end
    end
end