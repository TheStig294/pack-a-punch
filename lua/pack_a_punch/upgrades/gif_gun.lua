local UPGRADE = {}
UPGRADE.id = "gif_gun"
UPGRADE.class = "weapon_ttt_meme_gun"
UPGRADE.name = "GIF Gun"
UPGRADE.desc = "x2 ammo, memes are animated GIFs!"
UPGRADE.ammoMult = 2
local files = file.Find("materials/ttt_pack_a_punch/gif_gun/*", "GAME")
local maxMemeCount = 0

for _, image in ipairs(files) do
    if string.GetExtensionFromFilename(image) == "vmt" then
        maxMemeCount = maxMemeCount + 1
    end
end

-- Forcing clients to download all images, including custom ones just sitting in the server materials folder
for _, fileName in ipairs(files) do
    resource.AddFile("materials/ttt_pack_a_punch/gif_gun/" .. fileName)
end

function UPGRADE:Apply(SWEP)
    -- It really helps when you can just add your own hooks to your own weapon...
    if SERVER then
        self:AddHook("MemeGunSpawnedMeme", function(meme, gun)
            if self:IsUpgraded(gun) then
                meme:SetNWInt("PAPGifNumber", math.random(maxMemeCount))
            end
        end)
    end

    if CLIENT then
        -- Populate meme gun table
        local memeMaterials = {}

        for _, image in ipairs(files) do
            if string.GetExtensionFromFilename(image) == "vmt" then
                local mat = Material("ttt_pack_a_punch/gif_gun/" .. image)
                table.insert(memeMaterials, mat)
            end
        end

        -- Set the meme material
        -- (Material MUST be an UnlitGeneric and have "$nocull 1" set for it to work!)
        self:AddHook("MemeGunSetMaterial", function(meme)
            local gifNumber = meme:GetNWInt("PAPGifNumber", 0)
            if gifNumber ~= 0 then return memeMaterials[gifNumber] end
        end)
    end
end

TTTPAP:Register(UPGRADE)