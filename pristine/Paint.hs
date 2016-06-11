module Paint where
import Rumpus
import qualified Data.Sequence as Seq

maxBlots = 1000
start :: Start
start = do

    initialPosition <- getPosition
    setState (initialPosition, Seq.empty :: Seq EntityID)
    myDragContinues ==> \_ -> withState $ \(lastPosition, blots) -> do
        newPose <- getPose
        let newPosition = newPose ^. translation
        when (distance lastPosition newPosition > 0.05) $ do
            newBlot <- spawnChild $ do
                myPose          ==> newPose
                myShape         ==> Cube
                mySize          ==> 0.1
                myTransformType ==> AbsolutePose
                myColor         ==> colorHSL
                    (newPosition ^. _x) 0.7 0.8
            return ()

            let (newBlots, oldBlots) = Seq.splitAt maxBlots blots
            forM_ oldBlots removeEntity
            setState (newPosition, newBlot <| newBlots)
    return ()
