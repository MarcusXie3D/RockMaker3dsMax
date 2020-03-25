-- author: Marcus Xie
countPerName = 1

rollout RockMaker "Rock Maker"
(
    button placeRocks "Place Rocks" width:100 enabled:true
    label placingMode "Placing Mode Off"
    spinner spinnerIrregularitySize "" range:[1,10,5] type:#integer pos:[12,45] width:40 tooltip:"Size of the objects displacement"
    label labelIrregularitySize ": Irregularity Size" offset:[40,-20] align:#left tooltip:"Size of the objects displacement"
    spinner spinnerSmoothness "" range:[0,20,10] type:#integer pos:[12,65] width:40 tooltip:"Roughness of the object"
    label labelSmoothness ": Roughness" offset:[40,-20] align:#left tooltip:"Roughness of the object"
    checkbox checkboxOptimize "Optimize result" pos:[12,85] tooltip:"Optimize and collapse geometry" checked:true
	spinner spinnerOptimize "" range:[10,90,30] type:#integer pos:[105,85] width:40 enabled:true tooltip:"Percent of verticies to remain after optimization"
	label labelPercent "%" offset:[135,-20] align:#left tooltip:"Percent of verticies to remain after optimization"
    progressbar progress width:165 height:6 offset:[-3,0] value:0
	label progressLabel " status: ready" offset:[-1,-5] style_sunkenedge:true width:165 height:16 tooltip:"Status Bar"
    edittext rockName "Name" text:"rock"

    fn makeRock position = 
    (
        -- control how far the progress bar goes in each step
        building = 0.5
        buildingStep = building / 7.0
        optimizing = 1.0 - building
        optimizingStep = optimizing / 2.0
        progress.value  = 0.0
		progressLabel.text = (" status: Building ")

        -- Variables
        rockBoxSegs = 5
        -- make each rock varies in size
        rockBoxSidesX = (random 10 20)
        rockBoxSidesY = (random 10 20)
        rockBoxSidesZ = (random 5 15)
        -- controls how deep the surface indents in
        rockDisplaceValNoise = ((random -6.50 -5.5)*(spinnerSmoothness.value / 5)) -- spinnerSmoothness.value
        -- controls how large the details are
        rockDisplaceMapSize = (spinnerIrregularitySize.value * 10)

        -- Create new geo
        newRock = box length:rockBoxSidesX width:rockBoxSidesY height:rockBoxSidesZ lengthsegs:rockBoxSegs heightsegs:rockBoxSegs widthsegs:rockBoxSegs
        
        -- a rounder holistic shape is always preferred
        addmodifier newRock (spherify PERCENT:(random 80 100) )
        -- for the lack of segments, there're acute angles, here we smooth them as well as add more vertices for the sake of further modification
        addmodifier newRock (turbosmooth iterations:2)
        -- push the progress bar a bit forward
        progress.value  = buildingStep * 1.0 * 100.0

        -- Create large shape displace
        -- create a map of Worley noise, which is a bubbles-ish pattern
        newCellular = cellular size:(random 11 15)
        -- strength controls how deep the surface indents in, and length / width / height resize the modifier, as how tile a texture
        newDisplace = (displace strength:rockDisplaceValNoise maptype:2 length:rockDisplaceMapSize width:rockDisplaceMapSize height:rockDisplaceMapSize lumCenterEnable:on lumCenter: 1)
        addmodifier newRock newDisplace
        -- attach the bubbles-ish map to the displace modifier
        newDisplace.map = newCellular
        -- push the progress bar a bit forward
        progress.value  = buildingStep * 2.0 * 100.0

        -- weld vertices together to reduce faces
        newWeld = (Vertex_Weld threshold:2.55)
        addmodifier newRock newWeld
        -- push the progress bar a bit forward
        progress.value  = buildingStep * 3.0 * 100.0
            
        newSub = subdivide threshold:1.3
        addmodifier newRock newSub
        -- push the progress bar a bit forward
        progress.value  = buildingStep * 4.0 * 100.0

        newWeld = (Vertex_Weld threshold:1.3)
        addmodifier newRock newWeld
        -- push the progress bar a bit forward
        progress.value  = buildingStep * 5.0 * 100.0

        newWeld = (Vertex_Weld threshold:1)
        addmodifier newRock newWeld
        -- push the progress bar a bit forward
        progress.value  = buildingStep * 6.0 * 100.0
            
        newRelax = (relax Keep_Boundary_Pts_Fixed: 1  Relax_Value: 0.5 iterations: 1)
        addmodifier newRock newRelax
        
        -- to avoid that the rock pokes too deep into the groud too. lower the pivot to lift the rock a little bit
        newRock.pivot.z -= 2.0
        newRock.pos = position

        newRock.scale = [.2,.2,.2]
        ResetScale newRock
        -- push the progress bar a bit forward
        progress.value  = buildingStep * 7.0 * 100.0
        
        if checkboxOptimize.checked == true then
        (
            progressLabel.text = (" status: Optimizing ")
            newOptimize = ProOptimizer LockMat:off VertexPercent:(spinnerOptimize.value)
            addmodifier newRock newOptimize
            validModifier newRock newOptimize
            newOptimize.Calculate = True
            progress.value  = (building + optimizingStep * 1.0) * 100.0
                
            newWelder = welder dontWeldSelectedEdges:off weldMethod:0 threshold:0.1
            addmodifier newRock newWelder
            -- convert to editable poly
            converttopoly newRock
        )
        
        -- give it a dark gray look 
        newRock.wirecolor = [20,20,20]
        
        -- give rocks different names
        newRock.name = rockName.text + (countPerName as string)
        countPerName += 1
        progressLabel.text = (" status: Done ")
        -- everything's done, progressive bar should be full now
        progress.value  = 100.0
    )

    on checkboxOptimize changed state do ( if checkboxOptimize.checked == true then (spinnerOptimize.enabled = true) else(spinnerOptimize.enabled = False))

    -- countPerName is the index appended after the name, if the name is changed, reset the index
    on rockName changed val do (countPerName = 1)

    on placeRocks pressed do
    (
        placingMode.text = "Placing Mode On, Right Click to Exit"
        mousePos = point3 0 0 0
        while true do
        (
            mousePos = pickPoint snap: #3D
            if mousePos == #RightClick then
                exit
            else
                makeRock(mousePos)
        )
        placingMode.text = "Placing Mode Off"
    )
)

createDialog RockMaker width:180

snapMode.active = true
snapMode.type = #3D
