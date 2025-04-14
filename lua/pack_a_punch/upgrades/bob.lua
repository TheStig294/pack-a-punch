local UPGRADE = {}
UPGRADE.id = "bob"
UPGRADE.class = "swep_rifle_viper"
UPGRADE.name = "B.O.B"
UPGRADE.desc = "Right-click to summon B.O.B, who shoots anyone but you!"

UPGRADE.convars = {
    {
        name = "pap_bob_duration",
        type = "int"
    }
}

local bobModel = "models/konnie/overwatch/bob_default.mdl"
local isBobModelInstalled = util.IsValidModel(bobModel)

local durationCvar = CreateConVar("pap_bob_duration", 15, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds duration B.O.B lasts", 5, 120)

function UPGRADE:Condition()
    return isBobModelInstalled and player.GetCount() ~= game.MaxPlayers()
end

function UPGRADE:Apply(SWEP)
    local function ToggleCloak(ent, cloakOn)
        if not IsValid(ent) then return end

        if cloakOn then
            ent:SetColor(Color(255, 255, 255, 0))
            ent:DrawShadow(false)
            ent:SetMaterial("models/effects/vol_light001")
            ent:SetRenderMode(RENDERMODE_TRANSALPHA)
            ent:EmitSound("weapons/physgun_off.wav")
        else
            ent:DrawShadow(true)
            ent:SetMaterial("")
            ent:SetRenderMode(RENDERMODE_NORMAL)
            ent:EmitSound("weapons/physgun_on.wav")
        end
    end

    local function FlyToPos(bob, targetPos, originPos)
        if not targetPos or not IsValid(bob) then return end
        originPos = originPos or bob:GetPos()

        if bob.TTTPAPBobSpawned then
            ToggleCloak(bob, true)
        end

        local totalReps = 100
        local timername = "TTTPAPBobFly" .. bob:EntIndex()

        timer.Create(timername, 0.01, totalReps, function()
            if not IsValid(bob) then
                timer.Remove(timername)

                return
            end

            local fraction = timer.RepsLeft(timername) / totalReps
            local lerpedVector = LerpVector(fraction, targetPos, originPos)
            lerpedVector:Add(Vector(0, 0, 10))
            bob:SetPos(lerpedVector)

            -- Get Bob unstuck if his last position gets him stuck in a wall or something
            if timer.RepsLeft(timername) == 0 then
                self:UnstuckPlayer(bob)
                ToggleCloak(bob, false)

                -- Do some cool impact landing effects when Bob first spawns in
                if not bob.TTTPAPBobSpawned then
                    local effect = EffectData()
                    effect:SetOrigin(lerpedVector)
                    util.Effect("HelicopterMegaBomb", effect, true, true)
                    sound.Play("BaseExplosionEffect.Sound", lerpedVector, 180, math.random(50, 150), math.random())
                    util.ScreenShake(lerpedVector, 1000, 40, 1, 5000, true)
                end

                bob.TTTPAPBobSpawned = true

                if bob.TTTPAPBobDespawning then
                    bob:Kick()
                end
            end
        end)
    end

    SWEP.PAPOldSecondaryAttack = SWEP.SecondaryAttack

    function SWEP:SecondaryAttack()
        if self.TTTPAPBobSummoned then return self:PAPOldSecondaryAttack() end

        -- Add a delay to setting the summon flag to the weapon, else prediction is going to call the old secondary attack prematurely
        timer.Simple(0, function()
            self.TTTPAPBobSummoned = true
        end)

        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local bob = player.CreateNextBot("B.O.B")

        timer.Simple(0.5, function()
            if not IsValid(bob) then return end
            bob:SpawnForRound(true)
            owner:EmitSound("ttt_pack_a_punch/bob/activate.mp3")
            bob.TTTPAPBobBot = true
            bob:SetModel(bobModel)
            -- Lets Bob walk through players to allow for flying to them
            bob:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
            bob:Give("weapon_zm_sledge")
            bob.TTTPAPBobOwner = owner
            -- Fly bob to his initial spawn pos
            local originPos = owner:GetUp() * 1000
            local targetPos = owner:GetEyeTrace().HitPos
            FlyToPos(bob, targetPos, originPos)
            bob:SetHealth(150)
            -- Making bob fly to the target player if stuck
            local timername = "TTTPAPBobStuckCheck" .. bob:EntIndex()

            timer.Create(timername, 1, 0, function()
                if not IsValid(bob) then
                    timer.Remove(timername)

                    return
                end

                local closestPlayerPos = IsValid(bob.TTTPAPBobClosestPlayer) and bob.TTTPAPBobClosestPlayer:GetPos() or nil

                if bob.TTTPAPBobSpawned and closestPlayerPos and bob:GetVelocity():LengthSqr() < 100 and bob:GetPos():DistToSqr(closestPlayerPos) > 2000 then
                    FlyToPos(bob, closestPlayerPos)
                end
            end)

            -- Bob flies away and disconnects after time is up
            timer.Simple(durationCvar:GetInt(), function()
                if IsValid(bob) then
                    bob.TTTPAPBobDespawning = true
                    FlyToPos(bob, originPos)
                end
            end)
        end)
    end

    local function IsJester(ply)
        return ply:GetRole() == ROLE_JESTER or ply.IsJesterTeam and ply:IsJesterTeam()
    end

    self:AddHook("StartCommand", function(bob, cmd)
        if not self:IsAlivePlayer(bob) or not bob.TTTPAPBobBot then return end
        cmd:ClearMovement()
        cmd:ClearButtons()
        -- Always try to find the closest player to Bob to attack
        local owner = bob.TTTPAPBobOwner
        local minDist
        local closestPly
        local bobPos = bob:GetPos()

        for _, ply in player.Iterator() do
            if not self:IsAlive(ply) or ply == bob or ply == owner or IsJester(ply) then continue end
            local dist = ply:GetPos():DistToSqr(bobPos)

            if not minDist or dist < minDist then
                minDist = dist
                closestPly = ply
            end
        end

        bob.TTTPAPBobClosestPlayer = closestPly
        if not self:IsAlivePlayer(closestPly) then return end
        local bobWeapon = bob:GetActiveWeapon()

        if IsValid(bobWeapon) and bobWeapon:Clip1() == 0 then
            bobWeapon:SetClip1(bobWeapon:GetMaxClip1())
        end

        if not bob.TTTPAPBobDespawning then
            -- Move forwards and shoot at the bot's normal walking speed
            cmd:SetForwardMove(bob:GetWalkSpeed())
            cmd:SetButtons(IN_ATTACK)
            -- Aim at our enemy
            cmd:SetViewAngles((closestPly:GetShootPos() - bob:GetShootPos()):GetNormalized():Angle())
            bob:SetEyeAngles((closestPly:GetShootPos() - bob:GetShootPos()):GetNormalized():Angle())
        end
    end)

    -- Prevent Bob from killing jesters
    self:AddHook("PlayerShouldTakeDamage", function(ply, inflictor)
        if IsValid(inflictor) and inflictor.TTTPAPBobBot and IsJester(ply) then return false end
    end)
end

function UPGRADE:Reset()
    if SERVER then
        for _, bob in ents.Iterator() do
            if bob.TTTPAPBobBot then
                bob:Kick()
            end
        end
    end
end

TTTPAP:Register(UPGRADE)