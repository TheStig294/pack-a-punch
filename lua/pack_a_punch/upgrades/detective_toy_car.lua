local UPGRADE = {}
UPGRADE.id = "detective_toy_car"
UPGRADE.class = "equip_airboat"
UPGRADE.name = "Detective Toy Car"
UPGRADE.desc = "Drive around in your very own little detective toy car!\nTakes damage from being shot."

UPGRADE.convars = {
    {
        name = "pap_detective_toy_car_damage_mult",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_detective_toy_car_place_range",
        type = "int"
    }
}

local damageMultCvar = CreateConVar("pap_detective_toy_car_damage_mult", 2.5, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage multiplier the detective car takes", 0, 10)

local placeRangeCvar = CreateConVar("pap_detective_toy_car_place_range", 200, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Maximum placement distance", 10, 10000)

local carModel = "models/simfphys_vehicle1/cozycoupe.mdl"

function UPGRADE:Condition()
    return util.IsValidModel(carModel)
end

function UPGRADE:Apply(SWEP)
    SWEP.ViewModel = ""
    SWEP.WorldModel = carModel
    SWEP.PlaceOffset = 10
    SWEP.DamageMult = damageMultCvar:GetFloat()
    SWEP.PlaceRange = placeRangeCvar:GetFloat()

    -- Scaling damage of the car so its health can effectively be adjusted
    self:AddHook("EntityTakeDamage", function(target, dmg)
        if target.IsDetectiveToyCarPaP and target.DamageMult then
            dmg:ScaleDamage(target.DamageMult)
            local driver = target:GetDriver()

            if IsValid(driver) then
                driver:SetHealth(driver:Health() - dmg:GetDamage() * 0.4 / damageMultCvar:GetFloat())

                if driver:Health() <= 0 then
                    driver:Kill()
                end
            end
        end
    end)

    -- Fix the driving controls not working
    if SERVER then
        self:AddHook("PlayerButtonUp", function(ply, btn)
            numpad.Deactivate(ply, btn)
        end)

        self:AddHook("PlayerButtonDown", function(ply, btn)
            numpad.Activate(ply, btn)
        end)
    end

    -- Spawns car where the player is looking
    self:ChangeHook(SWEP, "PrimaryAttack", false, function(self)
        if CLIENT or not IsFirstTimePredicted() then return end
        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:IsPlayer() then return end
        -- Don't place car if player is looking too far away
        local TraceResult = owner:GetEyeTrace()
        local startPos = TraceResult.StartPos
        local endPos = TraceResult.HitPos
        local dist = math.Distance(startPos.x, startPos.y, endPos.x, endPos.y)

        if dist >= self.PlaceRange then
            owner:PrintMessage(HUD_PRINTCENTER, "Look at the ground to place the car")

            return
        end

        -- Else, place the car down
        endPos.z = endPos.z + self.PlaceOffset
        local pitch, yaw, roll = owner:EyeAngles():Unpack()
        pitch = 0
        local car = simfphys.SpawnVehicleSimple("simfphys_vehicle4", endPos, Angle(pitch, yaw, roll))
        -- Set some properties for later to detect this is a toy car entity
        car.IsDetectiveToyCarPaP = true
        car.DamageMult = self.DamageMult
        -- Display a message in chat
        owner:ChatPrint("Press 'H' to honk the horn!")
        -- Once the car is spawned, remove the weapon, which should in turn remove the car hologram
        self:Remove()
    end)

    -- Right-click also spawns car
    function SWEP:SecondaryAttack()
        self:PrimaryAttack()
    end

    function SWEP:ShouldDropOnDie()
        return true
    end

    -- Draw hologram when player is placing down car
    function SWEP:DrawHologram()
        if not CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local TraceResult = owner:GetEyeTrace()
        local startPos = TraceResult.StartPos
        local endPos = TraceResult.HitPos
        local dist = math.Distance(startPos.x, startPos.y, endPos.x, endPos.y)

        if dist < self.PlaceRange then
            local hologram

            if IsValid(self.Hologram) then
                hologram = self.Hologram
            else
                -- Make the hologram see-through to indicate it isn't placed yet
                hologram = ClientsideModel(self.WorldModel)
                hologram:SetColor(Color(200, 200, 200, 200))
                hologram:SetRenderMode(RENDERMODE_TRANSCOLOR)
                self.Hologram = hologram
            end

            endPos.z = endPos.z + self.PlaceOffset
            local pitch, yaw, roll = owner:EyeAngles():Unpack()
            pitch = 0
            hologram:SetPos(endPos)
            hologram:SetAngles(Angle(pitch, yaw, roll))
            hologram:DrawModel()
        elseif IsValid(self.Hologram) then
            self.Hologram:Remove()
        end
    end

    function SWEP:Deploy()
        self:DrawHologram()
    end

    function SWEP:Think()
        self:DrawHologram()
    end

    function SWEP:OnRemove()
        if IsValid(self.Hologram) then
            self.Hologram:Remove()
        end
    end

    function SWEP:OwnerChanged()
        if IsValid(self.Hologram) then
            self.Hologram:Remove()
        end
    end

    function SWEP:Holster()
        if IsValid(self.Hologram) then
            self.Hologram:Remove()
        end

        return true
    end

    function SWEP:ShouldDrawViewModel()
        return false
    end

    -- Drawing world model so others can see you holding the car
    if CLIENT then
        local WorldModel = ClientsideModel(SWEP.WorldModel)
        -- Settings...
        WorldModel:SetSkin(1)
        WorldModel:SetNoDraw(true)

        function SWEP:DrawWorldModel()
            local _Owner = self:GetOwner()

            if IsValid(_Owner) then
                -- Specify a good position
                local offsetVec = Vector(40, 0, 50)
                local offsetAng = Angle(180, 180, 0)
                local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
                if not boneid then return end
                local matrix = _Owner:GetBoneMatrix(boneid)
                if not matrix then return end
                local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
                WorldModel:SetPos(newPos)
                WorldModel:SetAngles(newAng)
                WorldModel:SetupBones()
            else
                WorldModel:SetPos(self:GetPos())
                WorldModel:SetAngles(self:GetAngles())
            end

            WorldModel:DrawModel()
        end
    end
end

TTTPAP:Register(UPGRADE)