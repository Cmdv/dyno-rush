module DinoRush
  ( main
  ) where

import qualified SDL
import qualified SDL.Mixer as Mixer
import qualified SDL.Font as Font
import qualified Data.Text.IO as T

import           Control.Exception.Safe (MonadThrow, MonadCatch)
import           Control.Monad.IO.Class (MonadIO(..))
import           Control.Monad.Reader (MonadReader, ReaderT, runReaderT)
import           Control.Monad.State (MonadState, StateT, evalStateT)
import           SDL.Vect
import           System.Random

import           DinoRush.Config
-- import DinoRush.Effect.Audio
-- import DinoRush.Effect.Camera
-- import DinoRush.Effect.Clock
-- import DinoRush.Effect.Logger
-- import DinoRush.Effect.Renderer
-- import DinoRush.Effect.HUD
-- import DinoRush.Effect.Sfx
-- import DinoRush.Engine.Obstacle
-- import DinoRush.Wrapper.SDLInput
-- import DinoRush.Wrapper.SDLRenderer
-- import DinoRush.Manager.Input
-- import DinoRush.Manager.Scene
-- import DinoRush.Resource
-- import DinoRush.Runner
-- import DinoRush.Scene.Title
-- import DinoRush.Scene.Pause
-- import DinoRush.Scene.Play
-- import DinoRush.Scene.Death
-- import DinoRush.Scene.GameOver
-- import DinoRush.State

main :: IO ()
main = do
  SDL.initialize [SDL.InitVideo, SDL.InitAudio]
  Font.initialize
  Mixer.openAudio Mixer.defaultAudio 256
  window <- SDL.createWindow "Dino Rush" SDL.defaultWindow { SDL.windowInitialSize = V2 1280 720 }
  renderer <- SDL.createRenderer window (-1) SDL.defaultRenderer
  resources <- loadResources renderer
  mkObstacles <- streamOfObstacles <$> getStdGen
  let cfg = Config
        { cWindow = window
        , cRenderer = renderer
        , cResources = resources
        }
  runDinoRush cfg (initVars mkObstacles) mainLoop
  SDL.destroyWindow window
  freeResources resources
  Mixer.closeAudio
  Mixer.quit
  Font.quit
  SDL.quit

newtype DinoRush a = DinoRush (ReaderT Config (StateT Vars IO) a)
  deriving (Functor, Applicative, Monad, MonadReader Config, MonadState Vars, MonadIO, MonadThrow, MonadCatch)

runDinoRush :: Config -> Vars -> DinoRush a -> IO a
runDinoRush config v (DinoRush m) = evalStateT (runReaderT m config) v
