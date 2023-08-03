if engine.ActiveGamemode() ~= "terrortown" then return end

-- Modifying the basketball weapon to use TTTBase
hook.Add("InitPostEntity", "TTTPAPMoonballModifyBase", function()
    local basketballSWEP = weapons.GetStored("weapon_ballin")

    if basketballSWEP then
        basketballSWEP.Base = "weapon_tttbase"
    end
end)

SWEP.Base = "weapon_ballin"

-- Check if the moonball is a floor weapon or not
if ConVarExists("ttt_joke_weapons_moonball_spawn_on_floor") and not GetConVar("ttt_joke_weapons_moonball_spawn_on_floor"):GetBool() then
    SWEP.Kind = 317
    SWEP.Slot = 9
else
    SWEP.Kind = WEAPON_NADE
    SWEP.Slot = 3
end

local SWEPKind = SWEP.Kind
SWEP.PrintName = "Basketball"
SWEP.InLoadoutFor = nil
SWEP.AutoSpawnable = false
SWEP.AllowDrop = true
SWEP.ViewModelFlip = true
SWEP.DrawAmmo = false
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.ClipMax = 1
SWEP.Secondary.Ammo = "none"
SWEP.Icon = "vgui/entities/weapon_ballin"
SWEP.WorldModel = "models/basketball.mdl"
SWEP.PAPNoCamo = true
SWEP.PAPDesc = "A basketball that can be picked up again!"
SWEP.stopdoinganimpls = true
-- Add a hook to give the basketball weapon to a player if they interact with the thrown ball entity
local hookAdded = false

function SWEP:Initialize()
    if SERVER and not hookAdded then
        hook.Add("PlayerUse", "PAPMoonballUseBasketball", function(ply, ent)
            if not IsValid(ent) then return end
            local model = ent:GetModel()

            if model and model == "models/basketball.mdl" and ent:GetClass() == "prop_physics" then
                -- Remove weapons of the same kind when trying to pick up the basketball
                for _, wep in ipairs(ply:GetWeapons()) do
                    if wep.Kind == SWEPKind then
                        ply:StripWeapon(wep:GetClass())
                    end
                end

                ply:Give("weapon_ttt_moonball_pap")

                timer.Simple(0.1, function()
                    ply:SelectWeapon("weapon_ttt_moonball_pap")
                end)

                ent:Remove()
            end
        end)
    end

    timer.Simple(0.1, function()
        if not IsValid(self) then return end
        self:SetClip1(1)
    end)
end

function SWEP:Equip()
    self:SetClip1(1)
    self:SetNWBool("IsPackAPunched", true)
    self.timerName = "ballinMultiplier" .. self:GetOwner():Name()
    self:SetHoldType("knife")
    self.releaseCheck = false
    self.releaseCheck2 = false
    self.isReloading = false
end

function SWEP:PrimaryAttack()
    self.BaseClass.PrimaryAttack(self)
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
                self:SetNextPrimaryFire(CurTime() + self.Primary.FireDelay)
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
                self:SetNextSecondaryFire(CurTime() + (self.Primary.FireDelay + 0.3))
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
    if (not owner:IsValid()) then return end
    -- Play the shoot sound we precached earlier!
    self:EmitSound(self.ShootSound)
    -- If we're the client then this is as much as we want to do.
    -- We play the sound above on the client due to prediction.
    -- ( if we didn't they would feel a ping delay during multiplayer )
    if (CLIENT) then return end
    -- Create a prop_physics entity
    local entThrown = ents.Create("prop_physics")
    -- Always make sure that created entities are actually created!
    if (not entThrown:IsValid()) then return end
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

    if (IsValid(owner)) then
        entThrown:SetOwner(owner)
    end

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

    if (not phys:IsValid()) then
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

    -- Assuming we're playing in Sandbox mode we want to add this
    -- entity to the cleanup and undo lists. This is done like so.
    cleanup.Add(owner, "props", entThrown)
    undo.Create("Thrown Ball")
    undo.AddEntity(entThrown)
    undo.SetPlayer(owner)
    undo.Finish()

    if throwDown and IsValid(owner) then
        owner:EmitSound("ttt_moonball_pap/slam.mp3")
    end

    self:Remove()
end