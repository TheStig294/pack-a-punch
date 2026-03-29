local UPGRADE = {}
UPGRADE.id = "dog_spammer"
UPGRADE.class = "weapon_ysm_guarddog"
UPGRADE.name = "Dog Spammer"
UPGRADE.desc = "Spawn lots of dogs!"

function UPGRADE:Apply(SWEP)
    -- Originally created by Malivil
    -- Yorkshireman role hooks
    -- Make the dogs automatically attack anyone that damages the Yorkshireman if they don't already have an explicit target
    self:AddHook("PostEntityTakeDamage", function(ent, dmginfo, wasDamageTaken)
        if not wasDamageTaken then return end
        if not IsPlayer(ent) then return end
        if not ent:IsActiveYorkshireman() then return end
        -- Ignore these damage types and assume the rest are purposeful from a direct weapon
        if dmginfo:IsFallDamage() or dmginfo:IsExplosionDamage() then return end
        local dogs = ent.TTTPAPDogSpammerDogEnts or {}

        for _, dog in ipairs(dogs) do
            if not IsValid(dog) then continue end
            if dog:HasEnemy() then continue end
            local att = dmginfo:GetAttacker()
            if not IsPlayer(att) then continue end
            if not att:Alive() or att:IsSpec() then continue end
            dog:SetEnemy(att)
        end
    end)

    self:AddHook("PostPlayerDeath", function(ply)
        if not IsPlayer(ply) or not ply.TTTPAPDogSpammerDogEnts then return end

        for _, dog in ipairs(ply.TTTPAPDogSpammerDogEnts) do
            SafeRemoveEntity(dog)
        end

        ply.TTTPAPDogSpammerDogEnts = nil
    end)

    -- SWEP Functions
    SWEP.DogSpawned = false
    SWEP.DogEnt = nil
    SWEP.DogMaxSpawnDist = 200
    SWEP.NextReloadTime = 0

    function SWEP:SpawnDog()
        if CLIENT then return end
        if self.TTTPAPDogSpammerDogEnts ~= nil then return end
        local owner = self:GetOwner()
        if not IsPlayer(owner) then return end
        local tr = owner:GetEyeTrace()
        if not tr.Hit then return end
        if tr.HitPos:Distance(owner:GetPos()) > self.DogMaxSpawnDist then return end
        local pos = tr.HitPos + Vector(0, 0, 5)
        local ang = owner:EyeAngles()
        ang.x = 0
        self.TTTPAPDogSpammerDogEnts = {}
        owner.TTTPAPDogSpammerDogEnts = {}
        local zOffset = 0

        for _ = 1, 10 do
            local dog = ents.Create("ttt_yorkshireman_dog")
            dog:SetController(owner)
            dog:SetPos(pos + Vector(0, 0, zOffset))
            zOffset = zOffset + 50
            dog:SetAngles(ang)
            dog:Spawn()
            dog:Activate()
            table.insert(self.TTTPAPDogSpammerDogEnts, dog)
            table.insert(owner.TTTPAPDogSpammerDogEnts, dog)
        end
    end

    function SWEP:PrimaryAttack()
        if self.TTTPAPDogSpammerDogEnts == nil then
            self:SpawnDog()

            return
        end

        for _, dog in ipairs(self.TTTPAPDogSpammerDogEnts) do
            if not IsValid(dog) or not dog:Alive() then continue end
            local owner = self:GetOwner()
            if not IsPlayer(owner) then continue end
            local tr = owner:GetEyeTrace()

            if tr.Hit and IsValid(tr.Entity) then
                owner:EmitSound("yorkshireman/whistle_attack.mp3", 100, 100, 1, CHAN_WEAPON)
                dog:SetEnemy(tr.Entity)
            end
        end
    end

    function SWEP:SecondaryAttack()
        if self.TTTPAPDogSpammerDogEnts == nil then
            self:SpawnDog()

            return
        end

        for _, dog in ipairs(self.TTTPAPDogSpammerDogEnts) do
            if not IsValid(dog) or not dog:Alive() then continue end

            if dog:HasEnemy() then
                local owner = self:GetOwner()

                if IsPlayer(owner) then
                    owner:EmitSound("yorkshireman/whistle_return.mp3", 50, 100, 1, CHAN_WEAPON)
                end

                dog:ClearEnemy()
            end
        end
    end

    function SWEP:Reload()
        if self.TTTPAPDogSpammerDogEnts == nil then
            self:SpawnDog()

            return
        end

        for _, dog in ipairs(self.TTTPAPDogSpammerDogEnts) do
            if not IsValid(dog) or not dog:Alive() then continue end
            local curTime = CurTime()
            if curTime < self.NextReloadTime then continue end

            if dog:IsStuck() then
                local owner = self:GetOwner()

                if IsPlayer(owner) then
                    owner:EmitSound("yorkshireman/whistle_return.mp3", 50, 100, 1, CHAN_WEAPON)
                end

                self.NextReloadTime = curTime + dog.StuckTime
                dog:Unstuck()
            end
        end
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        if ply.TTTPAPDogSpammerDogEnts then
            for _, dog in ipairs(ply.TTTPAPDogSpammerDogEnts) do
                SafeRemoveEntity(dog)
            end

            ply.TTTPAPDogSpammerDogEnts = nil
        end
    end
end

TTTPAP:Register(UPGRADE)