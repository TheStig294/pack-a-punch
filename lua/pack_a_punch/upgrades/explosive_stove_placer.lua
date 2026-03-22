local UPGRADE = {}
UPGRADE.id = "explosive_stove_placer"
UPGRADE.class = "weapon_chf_stoveplacer"
UPGRADE.name = "Explosive Stove Placer"
UPGRADE.desc = "Goes nuts"

function UPGRADE:Apply(SWEP)
    local foodTypes = {CHEF_FOOD_TYPE_BURGER, CHEF_FOOD_TYPE_HOTDOG, CHEF_FOOD_TYPE_FISH}

    local function SpawnRandomFood(spawnPos, placer)
        local food = ents.Create("ttt_chef_food")
        -- Spawn the food slightly in front of the stove
        food:SetPos(spawnPos)

        if IsValid(placer) then
            food:SetChef(placer)
        end

        food:SetFoodType(foodTypes[math.random(#foodTypes)])

        if math.random() < 0.5 then
            food:SetBurnt(true)
        end

        food:Spawn()
        local phys = food:GetPhysicsObject()

        if IsValid(phys) then
            phys:SetVelocity(Vector(math.Rand(-1000, 1000), math.Rand(-1000, 1000), 1000))
        end
    end

    local function ExplodeStove(stove, placer)
        local stovePos = stove:GetPos()
        stove:EmitSound("ambient/explosions/explode_3.wav")
        local explode = ents.Create("env_explosion")
        explode:SetPos(stovePos)
        explode:SetOwner(placer)
        explode:SetKeyValue("iMagnitude", 250)
        explode:SetKeyValue("iRadiusOverride", 250)
        explode:Spawn()
        explode:Fire("Explode", 0, 0)
        -- Leaves a bunch of fire on exploding
        local tr = util.QuickTrace(stovePos, Vector(0, 0, -1))
        StartFires(stovePos, tr, 20, 40, false, placer)

        for _ = 1, 20 do
            SpawnRandomFood(stovePos, placer)
        end

        stove:Remove()
    end

    local function ApplyStoveUpgrade(stove, placer)
        function stove:Use(_)
            if self.PAPExplosiveStovePlacerIsActive then return end
            self.PAPExplosiveStovePlacerIsActive = true
            local timername = "TTTPAPExplosiveStoveTimer" .. stove:EntIndex()
            self:WeldToGround(false)

            timer.Create(timername, 1, 30, function()
                if not IsValid(stove) then
                    timer.Remove(timername)

                    return
                end

                self:AddFire()
                SpawnRandomFood(stove:GetPos() + Vector(0, 0, 100), placer)
                local phys = self:GetPhysicsObject()

                if IsValid(phys) then
                    phys:SetVelocity(Vector(math.Rand(-100, 100), math.Rand(-100, 100), math.Rand(0, 1000)))
                end

                if timer.RepsLeft(timername) == 0 then
                    ExplodeStove(stove, placer)
                end
            end)
        end
    end

    self:AddToHook(SWEP, "PrimaryAttack", function()
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end

        timer.Simple(0.1, function()
            if not IsValid(owner) then return end

            for _, stove in ipairs(ents.FindByClass("ttt_chef_stove")) do
                local placer = stove:GetPlacer()
                if not IsValid(placer) then continue end

                if placer == owner and not self:IsUpgraded(stove) then
                    self:SetUpgraded(stove)
                    ApplyStoveUpgrade(stove, placer)
                end
            end
        end)
    end)
end

TTTPAP:Register(UPGRADE)