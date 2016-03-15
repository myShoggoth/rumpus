{-# LANGUAGE FlexibleContexts #-}
module BuildTree where
import Rumpus

createNewTimer = liftIO $ registerDelay (100 * 1000)
checkTimer = liftIO . atomically . readTVar

scale = [0,2,4,7,9]
randomNote = do
    i <- liftIO (randomRIO (0, length scale - 1))
    return (scale !! i)

start :: OnStart
start = do
    removeChildren

    cmpOnUpdate ==> withScriptData (\timer -> do
        shouldSpawn <- checkTimer timer
        if shouldSpawn 
            then do
                note <- randomNote
                sendPd "note" (Atom $ realToFrac note)
                pose <- getPose
                childID <- spawnEntity Transient $ do
                    cmpPose ==> pose & translation +~ 
                        (pose ^. _m33) !* (V3 0 0.3 0)
                    cmpShapeType ==> SphereShape
                    cmpSize ==> 0.03
                    cmpMass ==> 0.1
                    cmpColor ==> hslColor (note / 12) 0.9 0.8 1
                runEntity childID $ do
                    setLifetime 10
                    applyForce $ (pose ^. _m33) !* (V3 0 0.3 0)
                editScriptData $ \_ -> createNewTimer
            else return ())

    timer <- createNewTimer
    return (Just (toDyn timer))