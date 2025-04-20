local CollectionService = game:GetService("CollectionService")

for _, Ladder in CollectionService:GetTagged("Ladder") do
	Ladder.Transparency = 1
	Ladder.CanCollide = false
end