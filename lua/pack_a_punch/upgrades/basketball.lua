local UPGRADE = {}
UPGRADE.id = "basketball"
UPGRADE.class = "weapon_ttt_moonball"
UPGRADE.name = "Basketball"
UPGRADE.desc = "Left-click to pass.\nHold right-click, look up and jump to slam!"
UPGRADE.noCamo = true
UPGRADE.newClass = "weapon_ballin"

function UPGRADE:Condition(SWEP)
    return weapons.Get("weapon_ballin") ~= nil
end

-- Modifying the basketball weapon to use TTTBase, and a bunch of very irritating client-side errors fixed
if engine.ActiveGamemode() == "terrortown" then
    hook.Add("InitPostEntity", "TTTPAPMoonballModifyBase", function()
        local SWEP = weapons.GetStored("weapon_ballin")

        if SWEP then
            SWEP.Base = "weapon_tttbase"
            SWEP.PrintName = UPGRADE.name

            -- Check if the moonball is a floor weapon or not
            if ConVarExists("ttt_joke_weapons_moonball_spawn_on_floor") and not GetConVar("ttt_joke_weapons_moonball_spawn_on_floor"):GetBool() then
                SWEP.Kind = 317
                SWEP.Slot = 9
            else
                SWEP.Kind = WEAPON_NADE
                SWEP.Slot = 3
            end

            function SWEP:Equip()
                self:SetClip1(-1)
                self.timerName = "ballinMultiplier" .. self:GetOwner():Name()
                self:SetHoldType("knife")
                self.releaseCheck = false
                self.releaseCheck2 = false
                self.isReloading = false
            end

            function SWEP:Think()
                if self:IsValid() then
                    if not self.stopdoinganimpls and self.canAttack and not self.isReloading then
                        if self:GetOwner():KeyDown(IN_ATTACK) or self:GetOwner():KeyDown(IN_ATTACK2) then return end

                        if self:GetOwner():OnGround() and not self.playedIdle then
                            self:SendWeaponAnim(ACT_VM_IDLE)
                            self.playedIdle = true
                            self.playedAirIdle = false
                        end

                        if not self:GetOwner():OnGround() and not self.playedAirIdle then
                            self:SendWeaponAnim(ACT_VM_PULLBACK)
                            self.playedAirIdle = true
                            self.playedIdle = false
                        end
                    end

                    if self.timerName == nil then
                        self.timerName = "ballinMultiplier" .. self:GetOwner():Name()
                    end

                    if self.releaseCheck then
                        if not self:GetOwner():IsValid() then return end

                        if not timer.Exists(self.timerName) then
                            timer.Create(self.timerName, 0.1, 0, function()
                                if not self.chargeMultiplier then return end
                                self.chargeMultiplier = math.Clamp(self.chargeMultiplier + 0.13, 0, 4)
                            end)
                        end

                        if self:GetOwner():KeyReleased(IN_ATTACK) then
                            if self.Primary and self.Primary.FireDelay then
                                self:SetNextPrimaryFire(CurTime() + self.Primary.FireDelay)
                            end

                            self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
                            self:ThrowBall("models/basketball.mdl", false)
                            self:GetOwner():ViewPunch(Angle(2, 0, 0))
                            self.chargeMultiplier = 1
                        end
                    end

                    if self.releaseCheck2 then
                        if not self:GetOwner():IsValid() then return end

                        if not timer.Exists(self.timerName) then
                            timer.Create(self.timerName, 0.1, 0, function()
                                if not self.chargeMultiplier then return end
                                self.chargeMultiplier = math.Clamp(self.chargeMultiplier + 0.15, 0, 5)
                            end)
                        end

                        if self:GetOwner():KeyReleased(IN_ATTACK2) then
                            if self.Primary and self.Primary.FireDelay then
                                self:SetNextSecondaryFire(CurTime() + self.Primary.FireDelay + 0.3)
                            end

                            self:ThrowBall("models/basketball.mdl", true)
                            self:GetOwner():ViewPunch(Angle(-5, 0, 0))
                            self.chargeMultiplier = 1
                        end
                    end
                end
            end

            local function physCallback(ent, data)
                if not ent:GetNWBool("bouncesoundplayed") then
                    ent:EmitSound("ballinbounce")
                    ent:SetNWBool("bouncesoundplayed", true)

                    timer.Simple(0.2, function()
                        ent:SetNWBool("bouncesoundplayed", false)
                    end)
                end
            end

            function SWEP:ThrowBall(model_file, throwDown)
                self.canAttack = false

                if timer.Exists(self.timerName) then
                    timer.Remove(self.timerName)
                end

                local owner = self:GetOwner()
                self:GetOwner():SetAnimation(PLAYER_ATTACK1)

                if throwDown then
                    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

                    timer.Simple(0.8, function()
                        if IsValid(self) then
                            stopdoinganimpls = false
                            self.canAttack = true

                            if self:GetOwner():OnGround() then
                                self:SendWeaponAnim(ACT_VM_IDLE)
                            else
                                self:SendWeaponAnim(ACT_VM_PULLBACK)
                            end
                        end
                    end)

                    self.releaseCheck2 = false
                else
                    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

                    timer.Simple(0.5, function()
                        if IsValid(self) then
                            stopdoinganimpls = false
                            self.canAttack = true

                            if self:GetOwner():OnGround() then
                                self:SendWeaponAnim(ACT_VM_IDLE)
                            else
                                self:SendWeaponAnim(ACT_VM_PULLBACK)
                            end
                        end
                    end)

                    self.releaseCheck = false
                end

                -- Make sure the weapon is being held before trying to throw a chair
                if not owner:IsValid() then return end
                -- Play the shoot sound we precached earlier!
                self:EmitSound(self.ShootSound)
                -- If we're the client then this is as much as we want to do.
                -- We play the sound above on the client due to prediction.
                -- ( if we didn't they would feel a ping delay during multiplayer )
                if CLIENT then return end
                -- Create a prop_physics entity
                local entThrown = ents.Create("prop_physics")
                -- Always make sure that created entities are actually created!
                if not entThrown:IsValid() then return end
                -- Set the entity's model to the passed in model
                entThrown:SetModel(model_file)
                -- This is the same as owner:EyePos() + (self:GetOwner():GetAimVector() * 16)
                -- but the vector methods prevent duplicitous objects from being created
                -- which is faster and more memory efficient
                -- AimVector is not directly modified as it is used again later in the function
                local aimvec = owner:GetAimVector()
                local pos

                if not throwDown then
                    pos = aimvec * 30 -- This creates a new vector object
                    pos:Add(owner:EyePos()) -- This translates the local aimvector to world coordinates
                else
                    pos = aimvec * 50 -- This creates a new vector object
                    pos:Add(owner:EyePos()) -- This translates the local aimvector to world coordinates
                end

                -- Set the position to the player's eye position plus 16 units forward.
                entThrown:SetPos(pos)
                -- Set the angles to the player'e eye angles. Then spawn it.
                entThrown:SetAngles(owner:EyeAngles())

                if IsValid(self:GetOwner()) then
                    entThrown:SetOwner(self:GetOwner())
                end

                entThrown:SetNWBool("isBasketBall", true)
                entThrown:Spawn()
                entThrown:SetModelScale(1.3)

                if not throwDown then
                    util.SpriteTrail(entThrown, 0, Color(255, 255, 255, 60), false, 10, 1, 0.7, 1 / (15 + 1) * 0.5, "trails/smoke")
                else
                    util.SpriteTrail(entThrown, 0, Color(255, 255, 255, 100), false, 10, 1, 1.2, 1 / (15 + 1) * 0.5, "trails/smoke")
                end

                local callbackID

                if throwDown then
                    callbackID = entThrown:AddCallback("PhysicsCollide", function()
                        entThrown:EmitSound("ballindunk")
                        entThrown:RemoveCallback("PhysicsCollide", callbackID)
                    end)
                else
                    entThrown:AddCallback("PhysicsCollide", physCallback)
                    entThrown:SetNWBool("bouncesoundplayed", false)
                end

                -- Now get the physics object. Whenever we get a physics object
                -- we need to test to make sure its valid before using it.
                -- If it isn't then we'll remove the entity.
                local phys = entThrown:GetPhysicsObject()

                if not phys:IsValid() then
                    entThrown:Remove()

                    return
                end

                -- Now we apply the force - so the chair actually throws instead 
                -- of just falling to the ground. You can play with this value here
                -- to adjust how fast we throw it.
                -- Now that this is the last use of the aimvector vector we created,
                -- we can directly modify it instead of creating another copy
                phys:SetMaterial("gmod_bouncy")
                phys:SetMass(55)

                if not throwDown then
                    aimvec:Mul(25000 * self.chargeMultiplier)
                    phys:ApplyForceCenter(aimvec)
                    owner:SetVelocity(-owner:GetAimVector() * 300)
                else
                    aimvec:Mul(48000)
                    aimvec:Add(Vector(0, 0, -25000 * self.chargeMultiplier))
                    phys:ApplyForceCenter(aimvec)
                    phys:ApplyForceCenter(Vector(0, 0, -25000 * self.chargeMultiplier))
                    owner:SetVelocity(Vector(0, 0, -300 * self.chargeMultiplier))
                    local center = self:GetOwner():GetPos()
                    local radius = 90
                    local hullSize = Vector(radius, radius, radius) -- Adjust the size of the hull to fit your needs
                    local traceData = {}
                    traceData.start = center
                    traceData.endpos = center
                    traceData.filter = function(ent) return not (ent:GetNWBool("isBasketBall", false) or ent == owner or ent == entThrown) end
                    traceData.mins = -hullSize
                    traceData.maxs = hullSize
                    local traceResult = util.TraceHull(traceData)

                    if traceResult.Hit then
                        local hitEntity = traceResult.Entity

                        if hitEntity ~= owner and not hitEntity:GetNWBool("isBasketBall") then
                            owner:SetMoveType(MOVETYPE_NONE)
                            owner:ViewPunch(Angle(50, 0, 0))

                            timer.Simple(0.2, function()
                                owner:SetMoveType(MOVETYPE_WALK)
                            end)
                        end
                    end
                    -- Code to execute when no nearby surface or physics prop is hit
                end

                -- Assuming we're playing in Sandbox mode we want to add this
                -- entity to the cleanup and undo lists. This is done like so.
                cleanup.Add(owner, "props", entThrown)
                undo.Create("Thrown Ball")
                undo.AddEntity(entThrown)
                undo.SetPlayer(owner)
                undo.Finish()

                -- A lot of items can clutter the workspace.
                -- To fix this we add a 10 second delay to remove the chair after it was spawned.
                -- ent:IsValid() checks if the item still exists before removing it, eliminating errors.
                timer.Simple(10, function()
                    if entThrown and entThrown:IsValid() then
                        local p = entThrown:GetPos() -- Replace 'balloonEntity' with your balloon entity
                        local effectData = EffectData()
                        effectData:SetOrigin(p)
                        util.Effect("balloon_pop", effectData)
                        entThrown:Remove()
                    end
                end)
            end
        end
    end)
end

if SERVER then
    util.AddNetworkString("TTTPAPBasketballPickup")
end

if CLIENT then
    net.Receive("TTTPAPBasketballPickup", function()
        local SWEP = net.ReadEntity()
        UPGRADE:Apply(SWEP)
    end)
end

function UPGRADE:Apply(SWEP)
    -- Make the bounce sound quieter since it's by default too loud
    sound.Add({
        name = "ballinbounce",
        channel = CHAN_STATIC,
        volume = 0.3,
        level = 75,
        pitch = {80, 110},
        sound = "ballin/bounce.wav"
    })

    SWEP.PrintName = self.name
    SWEP.WorldModel = "models/basketball.mdl"
    local basketballKind = SWEP.Kind

    timer.Simple(0.1, function()
        if not IsValid(SWEP) then return end
        SWEP:SetClip1(-1)
    end)

    local function GiveBasketball(ply, ent)
        if not IsValid(ent) then return end
        local model = ent:GetModel()

        if model and model == "models/basketball.mdl" and ent:GetClass() == "prop_physics" then
            -- Strip weapons of the same kind when trying to pick up the basketball
            for _, wep in ipairs(ply:GetWeapons()) do
                local classname = WEPS.GetClass(wep)

                if wep.Kind == basketballKind and classname ~= self.ClassName then
                    ply:StripWeapon(classname)
                end
            end

            local newSWEP = ply:Give(self.newClass)

            timer.Simple(0.1, function()
                self:Apply(newSWEP)
                net.Start("TTTPAPBasketballPickup")
                net.WriteEntity(newSWEP)
                net.Broadcast()
                ply:SelectWeapon(self.newClass)
            end)

            ent:Remove()
        end
    end

    -- Add a hook to give the basketball weapon to a player if they interact with the thrown ball entity
    self:AddHook("PlayerUse", function(ply, ent)
        GiveBasketball(ply, ent)
    end)

    -- Make the basketball only damage players if it was slammed
    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local inflictor = dmg:GetInflictor()
        if not IsValid(inflictor) then return end
        local model = inflictor:GetModel()
        -- Checking if ent is basketball
        if not model or model ~= "models/basketball.mdl" or inflictor:GetClass() ~= "prop_physics" then return end
        -- Checking if basketball was slammed, then let the damage through
        -- Or if the hit entity is not the thrower, then also let the physics damage through
        if not inflictor.WasSlammed or (IsValid(inflictor.Thrower) and inflictor.Thrower == ent) then return true end
    end)

    -- Fix stupid client error basketball entity makes whenever you throw it from base mod...
    self:AddHook("Think", function()
        for _, ply in ipairs(player.GetAll()) do
            timer.Remove("ballinMultiplier" .. ply:Name())
        end
    end)

    function SWEP:Equip()
        self:SetClip1(-1)
        self.PAPUpgrade = UPGRADE
        self.timerName = "ballinMultiplier" .. self:GetOwner():Name()
        self:SetHoldType("knife")
        self.releaseCheck = false
        self.releaseCheck2 = false
        self.isReloading = false
    end

    function SWEP:PrimaryAttack()
        if self.releaseCheck2 then return end
        self:SendWeaponAnim(ACT_VM_IDLE_LOWERED)
        self.releaseCheck = true
        self.canAttack = true
        self.isReloading = false
        self.stopdoinganimpls = true
    end

    function SWEP:Reload()
        local owner = self:GetOwner()
        self:SendWeaponAnim(ACT_VM_PULLBACK_HIGH)

        if not self.stopdoinganimpls then
            self.stopdoinganimpls = true

            timer.Simple(3.9, function()
                self.stopdoinganimpls = false

                if IsValid(self) and IsValid(owner) then
                    if owner:OnGround() then
                        self:SendWeaponAnim(ACT_VM_IDLE)
                    else
                        self:SendWeaponAnim(ACT_VM_PULLBACK)
                    end
                end
            end)
        end

        if not self.isReloading then
            self.isReloading = true

            timer.Simple(3.9, function()
                self.stopdoinganimpls = false
                self.isReloading = false

                if IsValid(self) and IsValid(owner) then
                    if owner:OnGround() then
                        self:SendWeaponAnim(ACT_VM_IDLE)
                    else
                        self:SendWeaponAnim(ACT_VM_PULLBACK)
                    end
                end
            end)
        end
    end

    local function physCallback(basketball, colData)
        if not basketball:GetNWBool("bouncesoundplayed") then
            basketball:EmitSound("ballinbounce")
            basketball:SetNWBool("bouncesoundplayed", true)

            timer.Simple(0.2, function()
                if IsValid(basketball) then
                    basketball:SetNWBool("bouncesoundplayed", false)
                end
            end)
        end

        local hitEnt = colData.HitEntity

        -- Don't remove the basketball and give it to the hit player if the player is being slammed by the ball
        if not basketball.WasSlammed and self:IsAlivePlayer(hitEnt) then
            -- Make the player drop their currently held weapon (if they have one) to make the basketball left-click do a bit more
            local activeWep = hitEnt:GetActiveWeapon()

            if IsValid(activeWep) and WEPS.GetClass(activeWep) ~= self.ClassName and activeWep.AllowDrop then
                hitEnt:DropWeapon(activeWep)
            end

            GiveBasketball(hitEnt, basketball)
        end
    end

    function SWEP:ThrowBall(model_file, throwDown)
        self.releaseCheck = false
        self.releaseCheck2 = false
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self.canAttack = false

        if timer.Exists(self.timerName) then
            timer.Remove(self.timerName)
        end

        owner:SetAnimation(PLAYER_ATTACK1)

        if throwDown then
            self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

            timer.Simple(0.8, function()
                if IsValid(self) then
                    self.stopdoinganimpls = false
                    self.canAttack = true

                    if owner:OnGround() then
                        self:SendWeaponAnim(ACT_VM_IDLE)
                    else
                        self:SendWeaponAnim(ACT_VM_PULLBACK)
                    end
                end
            end)

            self.releaseCheck2 = false
        else
            self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

            timer.Simple(0.5, function()
                if IsValid(self) then
                    self.stopdoinganimpls = false
                    self.canAttack = true

                    if owner:OnGround() then
                        self:SendWeaponAnim(ACT_VM_IDLE)
                    else
                        self:SendWeaponAnim(ACT_VM_PULLBACK)
                    end
                end
            end)

            self.releaseCheck = false
        end

        -- Make sure the weapon is being held before trying to throw a chair
        if not owner:IsValid() then return end
        -- Play the shoot sound we precached earlier!
        self:EmitSound(self.ShootSound)
        -- If we're the client then this is as much as we want to do.
        -- We play the sound above on the client due to prediction.
        -- ( if we didn't they would feel a ping delay during multiplayer )
        if CLIENT then return end
        -- Create a prop_physics entity
        local entThrown = ents.Create("prop_physics")
        -- Always make sure that created entities are actually created!
        if not entThrown:IsValid() then return end
        -- Set the entity's model to the passed in model
        entThrown:SetModel(model_file)
        -- This is the same as owner:EyePos() + (owner:GetAimVector() * 16)
        -- but the vector methods prevent duplicitous objects from being created
        -- which is faster and more memory efficient
        -- AimVector is not directly modified as it is used again later in the function
        local aimvec = owner:GetAimVector()
        local pos

        if not throwDown then
            pos = aimvec * 30 -- This creates a new vector object
            pos:Add(owner:EyePos()) -- This translates the local aimvector to world coordinates
        else
            pos = aimvec * 50 -- This creates a new vector object
            pos:Add(owner:EyePos()) -- This translates the local aimvector to world coordinates
        end

        -- Set the position to the player's eye position plus 16 units forward.
        entThrown:SetPos(pos)
        -- Set the angles to the player'e eye angles. Then spawn it.
        entThrown:SetAngles(owner:EyeAngles())
        entThrown:SetNWBool("isBasketBall", true)
        entThrown:Spawn()
        entThrown:SetModelScale(1.3)

        if not throwDown then
            trail = util.SpriteTrail(entThrown, 0, Color(255, 255, 255, 60), false, 10, 1, 0.7, 1 / (15 + 1) * 0.5, "trails/smoke")
        else
            trail = util.SpriteTrail(entThrown, 0, Color(255, 255, 255, 100), false, 10, 1, 1.2, 1 / (15 + 1) * 0.5, "trails/smoke")
        end

        local callbackID

        if throwDown then
            callbackID = entThrown:AddCallback("PhysicsCollide", function()
                entThrown:EmitSound("ballindunk")
                entThrown:RemoveCallback("PhysicsCollide", callbackID)
            end)
        else
            entThrown:AddCallback("PhysicsCollide", physCallback)
            entThrown:SetNWBool("bouncesoundplayed", false)
        end

        -- Now get the physics object. Whenever we get a physics object
        -- we need to test to make sure its valid before using it.
        -- If it isn't then we'll remove the entity.
        local phys = entThrown:GetPhysicsObject()

        if not phys:IsValid() then
            entThrown:Remove()

            return
        end

        -- If the basketball touches a player shortly after the thrower slammed the ball, damage them and remove the ball
        entThrown.Thrower = owner

        if throwDown then
            entThrown.WasSlammed = true

            timer.Simple(1, function()
                if IsValid(entThrown) then
                    entThrown.WasSlammed = false
                end
            end)
        end

        -- Now we apply the force - so the chair actually throws instead 
        -- of just falling to the ground. You can play with this value here
        -- to adjust how fast we throw it.
        -- Now that this is the last use of the aimvector vector we created,
        -- we can directly modify it instead of creating another copy
        phys:SetMaterial("gmod_bouncy")
        phys:SetMass(55)

        if not throwDown then
            aimvec:Mul(25000 * self.chargeMultiplier)
            phys:ApplyForceCenter(aimvec)
            owner:SetVelocity(-owner:GetAimVector() * 300)
        else
            aimvec:Mul(48000)
            aimvec:Add(Vector(0, 0, -25000 * self.chargeMultiplier))
            phys:ApplyForceCenter(aimvec)
            phys:ApplyForceCenter(Vector(0, 0, -25000 * self.chargeMultiplier))
            owner:SetVelocity(Vector(0, 0, -300 * self.chargeMultiplier))
            local center = owner:GetPos()
            local radius = 90
            local hullSize = Vector(radius, radius, radius) -- Adjust the size of the hull to fit your needs
            local traceData = {}
            traceData.start = center
            traceData.endpos = center
            traceData.filter = function(ent) return not (ent:GetNWBool("isBasketBall", false) or ent == owner or ent == entThrown) end
            traceData.mins = -hullSize
            traceData.maxs = hullSize
            local traceResult = util.TraceHull(traceData)

            if traceResult.Hit then
                local hitEntity = traceResult.Entity

                if hitEntity ~= owner and not hitEntity:GetNWBool("isBasketBall") then
                    owner:SetMoveType(MOVETYPE_NONE)
                    owner:ViewPunch(Angle(50, 0, 0))

                    timer.Simple(0.2, function()
                        owner:SetMoveType(MOVETYPE_WALK)
                    end)
                end
            end
        end

        self:Remove()
    end

    if CLIENT then
        local WorldModel = ClientsideModel(SWEP.WorldModel)
        -- Settings...
        WorldModel:SetSkin(1)
        WorldModel:SetNoDraw(true)

        function SWEP:DrawWorldModel()
            local _Owner = self:GetOwner()

            if IsValid(_Owner) then
                -- Specify a good position
                local offsetVec = Vector(5, -2.7, -3.4)
                local offsetAng = Angle(180, -90, 0)
                local boneid = _Owner:LookupBone("ValveBiped.Bip01_L_Hand") -- Left Hand
                if not boneid then return end
                local matrix = _Owner:GetBoneMatrix(boneid)
                if not matrix then return end
                local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())

                if not self.WorldModeOffset then
                    self.WorldModeOffset = 0
                end

                newPos.z = newPos.z - self.WorldModeOffset

                if self.WorldModelMoveDown then
                    self.WorldModeOffset = self.WorldModeOffset + 1
                else
                    self.WorldModeOffset = self.WorldModeOffset - 1
                end

                WorldModel:SetPos(newPos)
                WorldModel:SetAngles(newAng)
                WorldModel:SetupBones()

                if self.WorldModelMoveDown and self.WorldModeOffset >= 32 then
                    self.WorldModelMoveDown = false
                elseif not self.WorldModelMoveDown and self.WorldModeOffset <= 0 then
                    self.WorldModelMoveDown = true
                end
            else
                WorldModel:SetPos(self:GetPos())
                WorldModel:SetAngles(self:GetAngles())
            end

            WorldModel:DrawModel()
        end
    end
end

TTTPAP:Register(UPGRADE)