{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE LambdaCase #-}
module Rumpus.Systems.Shared where
import PreludeExtra
import qualified Data.HashMap.Strict as Map

data ShapeType = Cube | Sphere 
    deriving (Eq, Show, Ord, Enum, Generic, FromJSON, ToJSON)

data InheritTransform = InheritFull | InheritPose

defineComponentKey ''InheritTransform
defineComponentKeyWithType "Shape"                  [t|ShapeType|]
defineComponentKeyWithType "Name"                   [t|String|]
defineComponentKeyWithType "Pose"                   [t|M44 GLfloat|]
defineComponentKeyWithType "PoseScaled"             [t|M44 GLfloat|]
defineComponentKeyWithType "Size"                   [t|V3 GLfloat|]
defineComponentKeyWithType "Color"                  [t|V4 GLfloat|]
defineComponentKeyWithType "Parent"                 [t|EntityID|]
defineComponentKeyWithType "Children"               [t|[EntityID]|]

-- Script System components (shared by Script and CodeEditor systems)
type Start  = EntityMonad ()
type Update = EntityMonad ()

defineComponentKey ''Start
defineComponentKey ''Update

defineComponentKeyWithType "State" [t|Dynamic|]


initSharedSystem :: (MonadIO m, MonadState ECS m) => m ()
initSharedSystem = do
    registerComponent "Name" myName (savedComponentInterface myName)
    registerComponent "Pose" myPose (savedComponentInterface myPose)
    registerComponent "PoseScaled" myPoseScaled $ (newComponentInterface myPoseScaled) 
        {   ciDeriveComponent = Just $ do
                -- More hax for release; one problem with this is that every entity will now
                -- get a cached scale (even those without shapes, poses or sizes, 
                -- since getSze and getPose return defaults)
                -- but I guess there aren't so many without shapes yet
                size <- getSize
                pose <- getPose
                myPoseScaled ==> pose !*! scaleMatrix size
        }
    registerComponent "Size" mySize (savedComponentInterface mySize)
    registerComponent "Color" myColor (savedComponentInterface myColor)
    registerComponent "ShapeType" myShape (savedComponentInterface myShape)
    registerComponent "Parent" myParent $ (newComponentInterface myParent)
        { ciDeriveComponent = Just $ do
            withComponent_ myParent $ \parentID -> do
                childID <- ask
                getEntityComponent parentID myChildren >>= \case
                    Nothing -> setEntityComponent myChildren [childID] parentID
                    Just _ ->  modifyEntityComponent parentID myChildren (return . (childID:))
        }
    registerComponent "Children" myChildren $ (newComponentInterface myChildren)
        { ciRemoveComponent = removeChildren
        }
    registerComponent "InheritTransform" myInheritTransform (newComponentInterface myInheritTransform)

    -- Allows Script and CodeEditor to access these
    registerComponent "Start"  myStart      (newComponentInterface myStart)
    registerComponent "Update" myUpdate     (newComponentInterface myUpdate)
    registerComponent "State"  myState      (newComponentInterface myState)

removeChildren :: (MonadState ECS m, MonadReader EntityID m, MonadIO m) => m ()
removeChildren = 
    withComponent_ myChildren (mapM_ removeEntity)


setEntityColor :: (MonadState ECS m, MonadIO m) => V4 GLfloat -> EntityID -> m ()
setEntityColor newColor entityID = setEntityComponent myColor newColor entityID

setColor :: (MonadReader EntityID m, MonadState ECS m, MonadIO m) => V4 GLfloat -> m ()
setColor newColor = setComponent myColor newColor


getEntityIDsWithName :: MonadState ECS m => String -> m [EntityID]
getEntityIDsWithName name = fromMaybe [] <$> withComponentMap myName (return . Map.keys . Map.filter (== name))

getEntityName :: MonadState ECS m => EntityID -> m String
getEntityName entityID = fromMaybe "No Name" <$> getEntityComponent entityID myName

getName :: (MonadReader EntityID m, MonadState ECS m) => m String
getName = getEntityName =<< ask

getEntityPose :: MonadState ECS m => EntityID -> m (M44 GLfloat)
getEntityPose entityID = fromMaybe identity <$> getEntityComponent entityID myPose

getPose :: (MonadReader EntityID m, MonadState ECS m) => m (M44 GLfloat)
getPose = getEntityPose =<< ask

getEntitySize :: MonadState ECS m => EntityID -> m (V3 GLfloat)
getEntitySize entityID = fromMaybe 1 <$> getEntityComponent entityID mySize

getSize :: (MonadReader EntityID m, MonadState ECS m) => m (V3 GLfloat)
getSize = getEntitySize =<< ask

getEntityColor :: MonadState ECS m => EntityID -> m (V4 GLfloat)
getEntityColor entityID = fromMaybe 1 <$> getEntityComponent entityID myColor

getColor :: (MonadReader EntityID m, MonadState ECS m) => m (V4 GLfloat)
getColor = getEntityColor =<< ask

getEntityInheritTransform :: (HasComponents s, MonadState s m) => EntityID -> m (Maybe InheritTransform)
getEntityInheritTransform entityID = getEntityComponent entityID myInheritTransform

getInheritTransform :: (HasComponents s, MonadState s m, MonadReader EntityID m) => m (Maybe InheritTransform)
getInheritTransform = getEntityInheritTransform =<< ask

getEntityChildren :: (HasComponents s, MonadState s m) => EntityID -> m [EntityID]
getEntityChildren entityID = fromMaybe [] <$> getEntityComponent entityID myChildren

