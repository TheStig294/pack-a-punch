local UPGRADE = {}
UPGRADE.id = "loot_cracker"
UPGRADE.class = "weapon_ttt_cracker"
UPGRADE.name = "Loot Cracker"
UPGRADE.desc = "Sprays out items on opening!"

UPGRADE.convars = {
    {
        name = "pap_loot_cracker_item_count",
        type = "int"
    }
}

local itemCountCvar = CreateConVar("pap_loot_cracker_item_count", "8", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Number of items dropped", 1, 20)

function UPGRADE:Apply(SWEP)
    -- Code modified from the Loot Goblin by Noxx and Mal
    function SWEP:GiveShopItem(ply)
        ply:EmitSound("birthday.wav")
        local lootTable = {}

        timer.Create("TTTPAPLootCracker", 0.05, itemCountCvar:GetInt(), function()
            -- Rebuild the loot table if we run out
            if #lootTable == 0 then
                for _, v in ipairs(weapons.GetList()) do
                    if v and not v.AutoSpawnable and v.CanBuy and v.AllowDrop then
                        table.insert(lootTable, WEPS.GetClass(v))
                    end
                end
            end

            local pos = ply:GetPos() + Vector(0, 0, 100)
            local idx = math.random(#lootTable)
            local wep = lootTable[idx]
            table.remove(lootTable, idx)
            local ent = ents.Create(wep)
            ent:SetPos(pos)
            ent:Spawn()
            local phys = ent:GetPhysicsObject()

            if phys:IsValid() then
                phys:ApplyForceCenter(Vector(math.Rand(-100, 100), math.Rand(-100, 100), 300) * phys:GetMass())
            end
        end)
    end
end

TTTPAP:Register(UPGRADE)