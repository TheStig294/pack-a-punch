TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

TTT_PAP_UPGRADES.weapon_zom_claws = {
    name = "Braaaaaains",
    desc = "Makes zombie sounds for you!",
    firerateMult = 1,
    func = function(SWEP)
        if CLIENT then return end

        if IsValid(SWEP:GetOwner()) then
            local timerName = "TTTPAPZombieClawSounds" .. SWEP:EntIndex()

            timer.Create("TTTPAPZombieClawSounds" .. SWEP:EntIndex(), 3, 0, function()
                if not IsValid(SWEP) or not IsValid(SWEP:GetOwner()) then
                    timer.Remove(timerName)

                    return
                end

                SWEP:GetOwner():EmitSound("ttt_pack_a_punch/zombie_claws/zombie" .. math.random(12) .. ".mp3")
                SWEP:GetOwner():EmitSound("ttt_pack_a_punch/zombie_claws/zombie" .. math.random(12) .. ".mp3")
            end)
        end

        function SWEP:Deploy()
            local owner = self:GetOwner()
            if not IsValid(owner) then return end
            local timerName = "TTTPAPZombieClawSounds" .. self:EntIndex()

            timer.Create("TTTPAPZombieClawSounds" .. self:EntIndex(), 3, 0, function()
                if not IsValid(self) or not IsValid(owner) then
                    timer.Remove(timerName)

                    return
                end

                owner:EmitSound("ttt_pack_a_punch/zombie_claws/zombie" .. math.random(12) .. ".mp3")
                owner:EmitSound("ttt_pack_a_punch/zombie_claws/zombie" .. math.random(12) .. ".mp3")
            end)

            return self.BaseClass.Deploy(self)
        end

        function SWEP:Holster(weapon)
            timer.Remove("TTTPAPZombieClawSounds" .. self:EntIndex())

            return self.BaseClass.Holster(self, weapon)
        end

        function SWEP:OnRemove()
            timer.Remove("TTTPAPZombieClawSounds" .. self:EntIndex())
            if self.BaseClass.OnRemove then return self.BaseClass.OnRemove(self) end
        end
    end
}