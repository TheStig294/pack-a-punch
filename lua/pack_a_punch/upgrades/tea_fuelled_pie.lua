local UPGRADE = {}
UPGRADE.id = "tea_fuelled_pie"
UPGRADE.class = "weapon_ysm_pie"
UPGRADE.name = "Tea Fuelled Pie"
UPGRADE.desc = "Massively buffs your dog,\n1-shot kills, has a ton of health and moves super fast!"

function UPGRADE:Apply(SWEP)
    local function BuffDog(dog)
        if not IsValid(dog) or dog:GetClass() ~= "ttt_yorkshireman_dog" then return end
        UPGRADE:SetUpgraded(dog)
        dog:SetModelScale(2, 2)
        dog:SetDamage(10000)
        dog:SetHealth(10000)
        dog:SetCustomCollisionCheck(true)

        if SERVER then
            dog:SetMaxHealth(10000)
            dog.IdleSpeed = dog.IdleSpeed * 2
            dog.WalkSpeed = dog.WalkSpeed * 2
            dog.RunSpeed = dog.RunSpeed * 2

            -- Have to override the unstuck function so the dog doesn't respawn un-upgraded
            function dog:Unstuck()
                local stuckDist = self.StuckDist + (self.StuckStep * self.StuckIterations)

                -- If we're stuck in our enemy just let it go
                if IsValid(self.Enemy) and self:GetRangeSquaredTo(self.Enemy) < stuckDist then
                    self.StuckIterations = self.StuckIterations + 1

                    return
                end

                self.StuckIterations = 0
                local controller = self:GetController()
                if not IsPlayer(controller) then return end
                self:ClearEnemy()
                -- Respawn the dog in front of their controller
                local controllerPos = controller:GetPos()
                local ang = controller:EyeAngles()
                local pos = controllerPos + ang:Forward() * 75
                ang.x = 0
                pos.z = controllerPos.z
                local newDog = ents.Create("ttt_yorkshireman_dog")
                newDog:SetController(controller)
                newDog:SetPos(pos + Vector(0, 0, 5))
                newDog:SetAngles(ang)
                newDog:Spawn()
                newDog:Activate()
                BuffDog(newDog)
                local wep = controller:GetWeapon("weapon_ysm_guarddog")

                if IsValid(wep) then
                    wep.DogEnt = newDog
                end

                controller.TTTYorkshiremanDog = newDog
                self:Remove()
            end
        end
    end

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        owner:LagCompensation(true)
        local dog = owner:GetEyeTrace().Entity
        owner:LagCompensation(false)

        if not IsValid(dog) or dog:GetClass() ~= "ttt_yorkshireman_dog" then
            owner:ClearQueuedMessage("TTTPAPysmInvalidDog")
            owner:ClearQueuedMessage("TTTPAPysmAlreadyUpgradedDog")
            owner:QueueMessage(MSG_PRINTCENTER, "Look at a dog to buff", nil, "TTTPAPysmInvalidDog")

            return
        elseif UPGRADE:IsUpgraded(dog) then
            owner:ClearQueuedMessage("TTTPAPysmInvalidDog")
            owner:ClearQueuedMessage("TTTPAPysmAlreadyUpgradedDog")
            owner:QueueMessage(MSG_PRINTCENTER, "That dog is already upgraded!", nil, "TTTPAPysmAlreadyUpgradedDog")

            return
        end

        dog:EmitSound("cr4ttt_dog_eat")
        dog:EmitSound("cr4ttt_dog_bite")
        owner:SetCustomCollisionCheck(true)
        BuffDog(dog)
    end

    self:AddHook("EntityEmitSound", function(data)
        local ent = data.Entity
        if not IsValid(ent) or ent:GetClass() ~= "ttt_yorkshireman_dog" then return end
        data.Pitch = data.Pitch / 2
        data.SoundLevel = data.SoundLevel * 2

        return true
    end)

    self:AddHook("ShouldCollide", function(ent1, ent2)
        if not IsValid(ent1) or not IsValid(ent2) then return end

        if ent1:GetClass() == "ttt_yorkshireman_dog" then
            if not IsValid(ent1:GetController()) or ent1:GetController() ~= ent2 then return end
        elseif ent2:GetClass() == "ttt_yorkshireman_dog" then
            if not IsValid(ent2:GetController()) or ent2:GetController() ~= ent2 then return end
        else
            return
        end

        return false
    end)
end

TTTPAP:Register(UPGRADE)