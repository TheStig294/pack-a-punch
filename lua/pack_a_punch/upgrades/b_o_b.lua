local UPGRADE = {}
UPGRADE.id = "b_o_b"
UPGRADE.class = "swep_rifle_viper"
UPGRADE.name = "B.O.B"
UPGRADE.desc = "Right-click to summon B.O.B, who shoots anyone not on your team!"
local bobModel = "models/konnie/overwatch/bob_default.mdl"
local isBobModelInstalled = util.IsValidModel(bobModel)

function UPGRADE:Condition()
    return isBobModelInstalled and player.GetCount() ~= game.MaxPlayers()
end

function UPGRADE:Apply(SWEP)
    function SWEP:SecondaryAttack()
        if CLIENT or self.TTTPAPBobSummoned then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local bob = player.CreateNextBot("B.O.B")

        timer.Simple(0.1, function()
            if not IsValid(bob) then return end
            self.TTTPAPBobSummoned = true
            owner:EmitSound("ttt_pack_a_punch/b_o_b/activate.mp3")
            bob.TTTPAPBobBot = true
            bob:SetModel(bobModel)
            bob:GodEnable()
            bob:Give("weapon_zm_sledge")
            bob.TTTPAPBobOwner = owner
            local originPos = owner:GetUp() * 1000
            local targetPos = owner:GetEyeTrace().HitPos
            local totalReps = 100
            local timername = "TTTPAPBobSummon" .. owner:SteamID64()

            timer.Create(timername, 0.01, totalReps, function()
                if not IsValid(bob) then
                    timer.Remove(timername)

                    return
                end

                local fraction = timer.RepsLeft(timername) / totalReps
                local lerpedVector = LerpVector(fraction, targetPos, originPos)
                lerpedVector:Add(Vector(0, 0, 10))
                bob:SetPos(lerpedVector)
            end)

            timer.Simple(10, function()
                if IsValid(bob) then
                    bob:Kick()
                end
            end)
        end)
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
            if not self:IsAlive(ply) or ply == bob or ply == owner then continue end
            local dist = ply:GetPos():DistToSqr(bobPos)

            if not minDist or dist < minDist then
                minDist = dist
                closestPly = ply
            end
        end

        if not self:IsAlivePlayer(closestPly) then return end
        -- Move forwards at the bots normal walking speed
        cmd:SetForwardMove(bob:GetWalkSpeed())
        -- Aim at our enemy
        cmd:SetViewAngles((closestPly:GetShootPos() - bob:GetShootPos()):GetNormalized():Angle())
        bob:SetEyeAngles((closestPly:GetShootPos() - bob:GetShootPos()):GetNormalized():Angle())
        local bobWeapon = bob:GetActiveWeapon()

        if IsValid(bobWeapon) and bobWeapon:Clip1() == 0 then
            bobWeapon:SetClip1(bobWeapon:GetMaxClip1())
        end

        cmd:SetButtons(IN_ATTACK)
    end)
end

function UPGRADE:Reset()
    if CLIENT then return end

    for _, ply in player.Iterator() do
        timer.Remove("TTTPAPBobSummon" .. ply:SteamID64())
    end

    for _, ent in ents.Iterator() do
        if ent.TTTPAPBobBot then
            ent:Kick()
        end
    end
end
-- TTTPAP:Register(UPGRADE)