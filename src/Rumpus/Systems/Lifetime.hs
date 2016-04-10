{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE FlexibleContexts #-}
module Rumpus.Systems.Lifetime where
import PreludeExtra

import Rumpus.Systems.Shared
import Rumpus.Systems.PlayPause
import Rumpus.Systems.Physics

data Lifetime = Lifetime UTCTime NominalDiffTime
defineComponentKey ''Lifetime

initLifetimeSystem :: MonadState ECS m => m ()
initLifetimeSystem = do
    registerComponent "Lifetime" myLifetime (newComponentInterface myLifetime)

tickLifetimeSystem :: (MonadIO m, MonadState ECS m) => m ()
tickLifetimeSystem = whenWorldPlaying $ do
    now <- liftIO getCurrentTime
    

    forEntitiesWithComponent myLifetime $ \(entityID, Lifetime birthtime lifetime) -> do
        let age = now `diffUTCTime` birthtime
        
        let fadeStart = lifetime - 1
        when (age > fadeStart) $ do
            let fadeProgress = lifetime - age
            size <- getEntitySize entityID
            setEntitySize (size * realToFrac fadeProgress) entityID

        when (age > lifetime) $ do
            removeEntity entityID
        

setLifetime :: (MonadIO m, MonadState ECS m, MonadReader EntityID m) => DiffTime -> m ()
setLifetime lifetime = do
    birth <- liftIO getCurrentTime
    myLifetime ==> Lifetime birth (realToFrac lifetime)




