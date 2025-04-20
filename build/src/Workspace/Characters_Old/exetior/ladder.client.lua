local CollectionService = game:GetService("CollectionService")

for _, ladder in CollectionService:GetTagged("Ladder") do
	ladder.Transparency = 0
	ladder.CanCollide = true
end