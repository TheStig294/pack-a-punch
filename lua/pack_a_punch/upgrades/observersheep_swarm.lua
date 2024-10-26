local UPGRADE = {}
UPGRADE.id = "observersheep_swarm"
UPGRADE.class = "weapon_ttt_detective_supersheep"
UPGRADE.name = "Observer Sheep Swarm"
UPGRADE.desc = "Sends out a swarm of observer sheep,\nwhich permanently marks players hit with an outline (+ a bonus sheep!)"
local trackedPlayers = {}

function UPGRADE:Apply(SWEP)
    self:SetClip(SWEP, -1)

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) or self.PAPUsed then return end
        self.PAPUsed = true
        owner.PAPObserverSheepSwarm = true
        self:EmitSound("ttt_supersheep/sheep_sound.wav")
        -- For some very annoying reason copying the base code was the only way I could avoid an occasional crash
        -- I have no idea what was causing it... It seemed to not like self:AddToHook() and similar ways of avoiding code-copying ¯\_(ツ)_/¯
        if CLIENT then return end
        local clearedEyeTrace = Vector(owner:GetEyeTrace().Normal.x, owner:GetEyeTrace().Normal.y, 0)
        local ent = ents.Create("ttt_pap_ent_detective_supersheep")
        if not IsValid(ent) then return end
        clearedEyeTrace = Vector(owner:GetEyeTrace().Normal.x, owner:GetEyeTrace().Normal.y, 0)
        local perpEyeTrace = Vector(-clearedEyeTrace.y, clearedEyeTrace.x, 0)
        local eyeAngles = owner:EyeAngles()
        local duckOffset = Vector(0, 0, 0)

        if owner:Crouching() then
            duckOffset = owner:GetViewOffsetDucked()
        end

        ent:SetPos(owner:EyePos() + clearedEyeTrace * 80 + Vector(0, 0, -40) + perpEyeTrace * -10 + duckOffset)
        ent:SetAngles(Angle(0, eyeAngles.y, 0))
        ent.Owner = owner
        ent:Spawn()
        ent:Activate()
        local phys = ent:GetPhysicsObject()

        if not IsValid(phys) then
            ent:Remove()

            return
        else
            -- Give it the PaP camo
            ent:SetPAPCamo()
            ent.PAPSheepChildren = {}

            -- Spawn non-solid extra sheep models 
            for i = 1, 10 do
                local child = ents.Create("prop_dynamic")
                child:SetModel("models/weapons/ent_ttt_detective_supersheep.mdl")
                -- Set all the child sheep at random positions
                local childPos = ent:GetPos() + VectorRand(-50, 50)
                child:SetPos(childPos)
                child:SetAngles(ent:GetAngles())
                child:SetModelScale(0.5)
                child:SetParent(ent)
                child:Spawn()
                local sequence = child:LookupSequence(ACT_VM_PRIMARYATTACK)
                child:ResetSequence(sequence)
                table.insert(ent.PAPSheepChildren, child)
            end
        end

        self:Remove()
    end

    function SWEP:SecondaryAttack()
    end

    function SWEP:Reload()
    end

    if SERVER then
        util.AddNetworkString("TTTPAPObserverSheepSwarmMarkPlayer")
    end

    if CLIENT then
        -- Add an outline around tracked players
        self:AddHook("PreDrawHalos", function()
            local outlinePlys = {}

            -- Stop tracking players after they die
            for _, ply in ipairs(trackedPlayers) do
                if IsValid(ply) and ply:Alive() and not ply:IsSpec() then
                    table.insert(outlinePlys, ply)
                end
            end

            halo.Add(outlinePlys, COLOR_GREEN, 1, 1, 2, true, true)
        end)

        -- This net message is sent by the upgraded observer sheep entity itself
        net.Receive("TTTPAPObserverSheepSwarmMarkPlayer", function()
            local ply = net.ReadPlayer()
            table.insert(trackedPlayers, ply)
        end)
    end
end

function UPGRADE:Reset()
    table.Empty(trackedPlayers)
end

TTTPAP:Register(UPGRADE)