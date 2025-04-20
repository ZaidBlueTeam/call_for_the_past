function onTouched(TestPart)
	wait(1.5)
script.Parent:remove()
end

script.Parent.Touched:connect(onTouched)