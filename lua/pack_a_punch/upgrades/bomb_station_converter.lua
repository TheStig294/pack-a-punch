local UPGRADE = {}
UPGRADE.id = "bomb_station_converter"
UPGRADE.class = "weapon_qua_station_bomb"
UPGRADE.name = "Bomb Station Converter"
UPGRADE.desc = "Converts *anything* into a bomb station!"

function UPGRADE:Apply(SWEP)
    SWEP.SingleUse = false

    -- What could go wrong? (The map entity returns false for IsValid() thankfully...)
    function SWEP:IsTargetValid(target, bone, primary)
        return IsValid(target) and not target.IsPAPStationBomb
    end

    -- Turns anything into a bomb station
    function SWEP:OnSuccess(target)
        local bomb = ents.Create("ttt_bomb_station")

        if not IsValid(bomb) then
            self:Error("ATTEMPT FAILED TRY AGAIN")

            return false
        end

        local owner = self:GetOwner()
        local pos = target:GetPos()
        local ang = target:GetAngles()
        SafeRemoveEntity(target)
        bomb:SetPos(pos)
        bomb:SetAngles(ang)
        bomb:Spawn()
        bomb:SetPlacer(owner)
        bomb:PhysWake()

        -- Including players...
        if target:IsPlayer() then
            target:SetNoDraw(true)
            target.IsPAPStationBomb = true
            target.PAPStationBomb = bomb
        end
    end

    -- Make any player with this weapon used on them a bomb station...
    self:AddHook("PlayerPostThink", function(ply)
        if not ply.IsPAPStationBomb then return end
        -- Remove the bomb and set the player to normal after they die
        local bomb = ply.PAPStationBomb

        if not IsValid(bomb) or not ply:Alive() or ply:IsSpec() then
            ply:SetNoDraw(false)
            ply.PAPStationBomb = nil
            ply.IsPAPStationBomb = false

            if IsValid(bomb) then
                bomb:Remove()
            end

            return
        end

        -- Some bombs are in the ground for some reason...
        local pos = ply:GetPos()

        if bomb.AddZ then
            pos.z = pos.z + 25
        end

        bomb:SetPos(pos)
        -- Makes the bomb look the same direction as the player
        local angles = ply:GetAngles()
        angles.x = 0
        bomb:SetAngles(angles)
    end)

    -- Replace the player's corpse with a station bomb
    self:AddHook("TTTOnCorpseCreated", function(rag)
        local ply = CORPSE.GetPlayer(rag)

        if IsValid(ply) and ply.IsPAPStationBomb then
            local bomb = ply.PAPStationBomb
            if not IsValid(ply) or not IsValid(bomb) then return end
            rag:SetNoDraw(true)
            local ragBomb = ents.Create("ttt_bomb_station")
            local owner = ply
            local pos = rag:GetPos()
            local ang = rag:GetAngles()
            ragBomb:SetParent(rag)
            ragBomb:SetPos(pos)
            ragBomb:SetAngles(ang)
            ragBomb:Spawn()
            ragBomb:SetPlacer(owner)
            ragBomb:PhysWake()
        end
    end)
end

-- Reset all players to not be a bomb station anymore at the end of the round
function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        if ply.IsPAPStationBomb then
            ply:SetNoDraw(false)
            ply.IsPAPStationBomb = false
            ply.PAPStationBomb = nil
        end
    end
end

TTTPAP:Register(UPGRADE)