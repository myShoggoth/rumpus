module Foo where
import Rumpus

start :: Start
start = do
    setSize (V3 0.5 0.5 0.1)
    setFloating True
    setColor (colorHSL 0.8 0.8 0.9)
    let makeChild i = spawnChild $ do
            myShape ==> Cube
            myProperties ==> [Holographic]
            mySize ==> 0.1
            myUpdate ==> do
               now1 <- getNow
               let now = now1 * 1 + (i * 0.05)
               let y = 5 * sin now
               setRotation (V3 1 0 1) now
               setPosition $ V3 (cos now * 5) y (-10)
               setColor    $ colorHSL (now*0.1) 0.8 0.6
               setSize     $ V3 9 0.01 (sin now)
    forM_ [0..100] $ \i -> do
        makeChild i
    -- Add a platform to teleport to
    spawnChild $ do
        myShape ==> Cube
        mySize ==> V3 2 0.1 2
        myPose ==> translateMatrix (V3 0 0 (-10))
        myProperties ==> [Floating,Teleportable]
    return ()

