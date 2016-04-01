{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
module RunAnalyzer where
import Rumpus

update :: OnUpdate
update = do
    withScriptData $ \receiver -> do
        rootID <- ask
        notes <- liftIO $ atomically $ exhaustChan receiver
        forM_ notes $ \case
            Atom (Float note) -> do
                headPose <- getHeadPose
                childID <- spawnEntity Transient $ do
                    cmpShapeType ==> CubeShape
                    cmpParent  ==> rootID
                    cmpPose    ==> headPose
                    cmpGravity ==> 0
                    cmpColor   ==> hslColor (realToFrac note / 100) 0.8 0.6
                let headOrient = poseFromMatrix headPose ^. posOrientation
                applyForceToEntity (rotate headOrient (V3 0 0 (-2))) childID
            _ -> return ()
