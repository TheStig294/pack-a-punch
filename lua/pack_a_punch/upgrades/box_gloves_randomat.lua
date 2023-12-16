local UPGRADE = {}
UPGRADE.id = "box_gloves_randomat"
UPGRADE.class = "weapon_randomat_boxgloves"
UPGRADE.name = "Box Gloves"
UPGRADE.desc = "Players you hit turn into boxes"

function UPGRADE:Apply(SWEP)
    local boxModel = "models/props_junk/cardboard_box001a.mdl"
    local sound_single = Sound("Weapon_Crowbar.Single")

    local function IsValidTarget(hitEnt)
        return hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll"
    end

    function SWEP:DoPunch(owner, onplayerhit)
        if not UPGRADE:IsPlayer(owner) then return end

        -- Don't let the owner keep punching after they've been knocked out
        if owner:GetNWBool("RdmtBoxingKnockedOut", false) then
            owner:StopSound(sound_scream)

            return
        end

        local spos = owner:GetShootPos()
        local sdest = spos + owner:GetAimVector() * 70
        local kmins = Vector(1, 1, 1) * -10
        local kmaxs = Vector(1, 1, 1) * 10

        local tr_main = util.TraceHull({
            start = spos,
            endpos = sdest,
            filter = owner,
            mask = MASK_SHOT_HULL,
            mins = kmins,
            maxs = kmaxs
        })

        local hitEnt = tr_main.Entity
        self:EmitSound(sound_single)

        if (IsValid(hitEnt) or tr_main.HitWorld) and not (CLIENT and not IsFirstTimePredicted()) then
            local edata = EffectData()
            edata:SetStart(spos)
            edata:SetOrigin(tr_main.HitPos)
            edata:SetNormal(tr_main.Normal)
            edata:SetSurfaceProp(tr_main.SurfaceProps)
            edata:SetHitBox(tr_main.HitBox)
            edata:SetEntity(hitEnt)

            if IsValidTarget(hitEnt) then
                util.Effect("BloodImpact", edata)
                owner:LagCompensation(false)
            else
                util.Effect("Impact", edata)
            end
        end

        if not CLIENT then
            owner:SetAnimation(PLAYER_ATTACK1)

            if IsValid(hitEnt) and IsValidTarget(hitEnt) then
                local dmg = DamageInfo()
                dmg:SetDamage(self.Primary.Damage)
                dmg:SetAttacker(owner)
                dmg:SetInflictor(self)
                dmg:SetDamageForce(owner:GetAimVector() * 5)
                dmg:SetDamagePosition(owner:GetPos())
                dmg:SetDamageType(DMG_SLASH)
                hitEnt:DispatchTraceAttack(dmg, spos + owner:GetAimVector() * 3, sdest)

                if not hitEnt.PAPBoxingBox and hitEnt:IsPlayer() then
                    local box = ents.Create("prop_dynamic")
                    box:SetPos(hitEnt:GetPos())
                    box:SetAngles(hitEnt:GetAngles())
                    box:SetModel(boxModel)
                    box:Spawn()
                    hitEnt:SetNoDraw(true)
                    hitEnt.PAPBoxingBox = box
                end

                -- Only call the callback if this punch isn't going to kill them
                local damage = GetConVar("randomat_boxingday_damage"):GetInt()

                if onplayerhit and damage < hitEnt:Health() then
                    onplayerhit(hitEnt)
                end
            end
        end
    end

    -- Make any player with this weapon used on them a box station...
    self:AddHook("PlayerPostThink", function(ply)
        if not IsValid(ply.PAPBoxingBox) then return end
        -- Remove the box and set the player to normal after they die
        local box = ply.PAPBoxingBox

        if not IsValid(box) or not ply:Alive() or ply:IsSpec() then
            ply:SetNoDraw(false)

            if IsValid(box) then
                box:Remove()
            end

            return
        end

        -- Some boxs are in the ground for some reason...
        local pos = ply:GetPos()

        if box.AddZ then
            pos.z = pos.z + 25
        end

        box:SetPos(pos)
        -- Makes the box look the same direction as the player
        local angles = ply:GetAngles()
        angles.x = 0
        box:SetAngles(angles)
    end)

    -- Replace the player's corpse with a station box
    self:AddHook("TTTOnCorpseCreated", function(rag)
        local ply = CORPSE.GetPlayer(rag)

        if IsValid(ply) and IsValid(ply.PAPBoxingBox) then
            rag:SetNoDraw(true)
            local ragbox = ents.Create("prop_dynamic")
            local pos = rag:GetPos()
            local ang = rag:GetAngles()
            ragbox:SetParent(rag)
            ragbox:SetPos(pos)
            ragbox:SetAngles(ang)
            ragbox:Spawn()
            ragbox:PhysWake()
        end
    end)

    -- Hide player ragdolls
    self:AddHook("Think", function()
        for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
            if IsValid(ent:GetNWEntity("RdmtBoxingRagdolledPly")) then
                ent:SetNoDraw(true)
            end
        end
    end)

    -- Remove boxes when players are revived
    self:AddHook("PlayerSpawn", function(ply)
        if IsValid(ply.PAPBoxingBox) then
            ply.PAPBoxingBox:Remove()
            ply.PAPBoxingBox = nil
        end
    end)
end

-- Reset all players to not be a box station anymore at the end of the round
function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply.PAPBoxingBox) then
            ply:SetNoDraw(false)
            ply.PAPBoxingBox = nil
        end
    end
end

TTTPAP:Register(UPGRADE)