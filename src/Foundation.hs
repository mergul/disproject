{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-deferred-out-of-scope-variables #-}

module Foundation where

import Chat
import Chat.Data
import Control.Monad.Logger (LogSource)
import qualified Data.ByteString as BS
import qualified Data.CaseInsensitive as CI
import Data.IORef
import qualified Data.Map ()
import qualified Data.Maybe ()
import Data.Text ()
import qualified Data.Text.Encoding ()
import qualified Data.Word8 as W8
import Database.Persist.Sql (ConnectionPool, runSqlPool)
import Import.NoFoundation
import Network.HTTP.Conduit ()
import Network.Wai as Wai
import Text.Hamlet (hamletFile)
import Text.Jasmine (minifym)
import Yesod.Auth.Dummy
import Yesod.Auth.OAuth2 ()
import qualified Yesod.Auth.OAuth2.Google as Google
import Yesod.Auth.OpenId (IdentifierType (Claimed), authOpenId)
-- import qualified Yesod.Core as Y
import Yesod.Core.Types (Logger)
import qualified Yesod.Core.Unsafe as Unsafe
import Yesod.Default.Util (addStaticContentExternal)

clientId :: Text
clientId = "608473106039-s9cape5vuremdroo7gsiohlgqpjg0dm1.apps.googleusercontent.com"

clientSecret :: Text
clientSecret = "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"

isWebSocketsReq :: Wai.Request -> Bool
isWebSocketsReq req =
  fmap CI.mk (lookup "upgrade" $ Wai.requestHeaders req) == Just "websocket"

hasTokenized :: Wai.Request -> Maybe Text
hasTokenized req = do
  case lookup "Authorization" $ Wai.requestHeaders req of
    Nothing -> Nothing
    Just authHead -> case BS.break W8.isSpace authHead of
      (strategy, token)
        | BS.map W8.toLower strategy == "bearer" ->
          Just $ decodeUtf8 $ BS.dropWhile W8.isSpace token
        | otherwise ->
          Nothing

-- | The foundation datatype for your application. This can be a good place to
-- keep settings and values requiring initialization before your application
-- starts running, such as database connections. Every handler will have
-- access to the data present here.
data App = App
  { appSettings :: AppSettings,
    -- | Settings for static file serving.
    appStatic :: Static,
    -- | Database connection pool.
    appConnPool :: ConnectionPool,
    appHttpManager :: Manager,
    appLogger :: Logger,
    appChat :: Chat,
    appWikiContent :: IORef (Map [Text] Text)
  }

data MenuItem = MenuItem
  { menuItemLabel :: Text,
    menuItemRoute :: Route App,
    menuItemAccessCallback :: Bool
  }

data MenuTypes
  = NavbarLeft MenuItem
  | NavbarRight MenuItem

-- This is where we define all of the routes in our application. For a full
-- explanation of the syntax, please see:
-- http://www.yesodweb.com/book/routing-and-handlers
--
-- Note that this is really half the story; in Application.hs, mkYesodDispatch
-- generates the rest of the code. Please see the following documentation
-- for an explanation for this split:
-- http://www.yesodweb.com/book/scaffolding-and-the-site-template#scaffolding-and-the-site-template_foundation_and_application_modules
--
-- This function also generates the following type synonyms:
-- type Handler = HandlerFor App
-- type Widget = WidgetFor App ()
mkYesodData "App" $(parseRoutesFile "config/routes.yesodroutes")

-- | A convenient synonym for creating forms.
type Form x = Html -> MForm (HandlerFor App) (FormResult x, Widget)

-- | A convenient synonym for database access functions.
type DB a =
  forall (m :: * -> *).
  (MonadUnliftIO m) =>
  ReaderT SqlBackend m a

-- Please see the documentation for the Yesod typeclass. There are a number
-- of settings which can be configured by overriding methods here.
instance Yesod App where
  -- Controls the base of generated URLs. For more information on modifying,
  -- see: https://github.com/yesodweb/yesod/wiki/Overriding-approot
  approot :: Approot App
  approot = ApprootRequest $ \app req ->
    case appRoot $ appSettings app of
      Nothing -> getApprootText guessApproot app req
      Just root -> root

  -- Store session data on the client in encrypted cookies,
  -- default session idle timeout is 120 minutes
  makeSessionBackend :: App -> IO (Maybe SessionBackend)
  makeSessionBackend _ =
    Just
      <$> defaultClientSessionBackend
        120 -- timeout in minutes
        "config/client_session_key.aes"

  -- Yesod Middleware allows you to run code before and after each handler function.
  -- The defaultYesodMiddleware adds the response header "Vary: Accept, Accept-Language" and performs authorization checks.
  -- Some users may also want to add the defaultCsrfMiddleware, which:
  --   a) Sets a cookie with a CSRF token in it.
  --   b) Validates that incoming write requests include that token in either a header or POST parameter.
  -- To add it, chain it together with the defaultMiddleware: yesodMiddleware = defaultYesodMiddleware . defaultCsrfMiddleware
  -- For details, see the CSRF documentation in the Yesod.Core.Handler module of the yesod-core package.
  yesodMiddleware :: ToTypedContent res => Handler res -> Handler res
  yesodMiddleware = defaultYesodMiddleware

  defaultLayout :: Widget -> Handler Html
  defaultLayout widget = do
    master <- getYesod
    mmsg <- getMessage

    muser <- maybeAuthPair
    mcurrentRoute <- getCurrentRoute

    -- Get the breadcrumbs, as defined in the YesodBreadcrumbs instance.
    (title, parents) <- breadcrumbs

    -- Define the menu items of the header.
    let menuItems =
          [ NavbarLeft $
              MenuItem
                { menuItemLabel = "Home",
                  menuItemRoute = ParthomeR,
                  menuItemAccessCallback = True
                },
            NavbarLeft $
              MenuItem
                { menuItemLabel = "New Post",
                  menuItemRoute = PartnewR,
                  menuItemAccessCallback = isJust muser
                },
            NavbarLeft $
              MenuItem
                { menuItemLabel = "Admin",
                  menuItemRoute = PartadminR,
                  menuItemAccessCallback = isJust muser
                },
            NavbarRight $
              MenuItem
                { menuItemLabel = "Profile",
                  menuItemRoute = PartprofileR,
                  menuItemAccessCallback = isJust muser
                },
            NavbarRight $
              MenuItem
                { menuItemLabel = "Login",
                  menuItemRoute = AuthR LoginR,
                  menuItemAccessCallback = isNothing muser
                },
            NavbarRight $
              MenuItem
                { menuItemLabel = "Logout",
                  menuItemRoute = AuthR LogoutR,
                  menuItemAccessCallback = isJust muser
                }
          ]

    let navbarLeftMenuItems = [x | NavbarLeft x <- menuItems]
    let navbarRightMenuItems = [x | NavbarRight x <- menuItems]

    let navbarLeftFilteredMenuItems = [x | x <- navbarLeftMenuItems, menuItemAccessCallback x]
    let navbarRightFilteredMenuItems = [x | x <- navbarRightMenuItems, menuItemAccessCallback x]

    -- We break up the default layout into two components:
    -- default-layout is the contents of the body tag, and
    -- default-layout-wrapper is the entire page. Since the final
    -- value passed to hamletToRepHtml cannot be a widget, this allows
    -- you to use normal widget features in default-layout.

    pc <- widgetToPageContent $ do
      addScript $ StaticR js_mystore_js
      $(widgetFile "default-layout")
      chatWidget
        ChatR
    withUrlRenderer $(hamletFile "templates/default-layout-wrapper.hamlet")

  -- The page to be redirected to when authentication is required.
  authRoute ::
    App ->
    Maybe (Route App)
  authRoute _ = Just $ AuthR LoginR

  isAuthorized ::
    -- \| The route the user is visiting.
    Route App ->
    -- \| Whether or not this is a "write" request.
    Bool ->
    Handler AuthResult
  -- Routes not requiring authentication.
  isAuthorized (AuthR _) _ = return Authorized
  isAuthorized (PostDetailsR _) _ = return Authorized
  isAuthorized (PartdetailsR _) _ = return Authorized
  isAuthorized CommentR _ = return Authorized
  isAuthorized FirstCustomerR _ = return Authorized
  isAuthorized HomeR _ = return Authorized
  isAuthorized PostNewR _ = return Authorized
  isAuthorized (ChatR _) _ = return Authorized
  isAuthorized FaviconR _ = return Authorized
  isAuthorized RobotsR _ = return Authorized
  isAuthorized (WikiR _) _ = return Authorized
  isAuthorized (StaticR _) _ = return Authorized
  -- the profile route requires that the user is authenticated, so we
  -- delegate to that function
  isAuthorized ProfileR _ = isAuthenticated
  isAuthorized AdminR _ = isAuthenticated
  isAuthorized AdminPageviewsR _ = isAuthenticated
  isAuthorized ParthomeR _ = return Authorized
  isAuthorized PartnewR _ = return Authorized
  isAuthorized PartadminR _ = isAuthenticated
  isAuthorized PartprofileR _ = isAuthenticated

  -- This function creates static content files in the static folder
  -- and names them based on a hash of their content. This allows
  -- expiration dates to be set far in the future without worry of
  -- users receiving stale content.
  addStaticContent ::
    -- \| The file extension
    Text ->
    -- \| The MIME content type
    Text ->
    -- \| The contents of the file
    LByteString ->
    Handler (Maybe (Either Text (Route App, [(Text, Text)])))
  addStaticContent ext mime content = do
    master <- getYesod
    let staticDir = appStaticDir $ appSettings master
    addStaticContentExternal
      minifym
      genFileName
      staticDir
      (StaticR . flip StaticRoute [])
      ext
      mime
      content
    where
      -- Generate a unique filename based on the content itself
      genFileName lbs = "autogen-" ++ base64md5 lbs

  -- What messages should be logged. The following includes all messages when
  -- in development, and warnings and errors in production.
  shouldLogIO :: App -> LogSource -> LogLevel -> IO Bool
  shouldLogIO app _source level =
    return $
      appShouldLogAll (appSettings app)
        || level == LevelWarn
        || level == LevelError

  makeLogger :: App -> IO Logger
  makeLogger = return . appLogger

-- Define breadcrumbs.
instance YesodBreadcrumbs App where
  -- Takes the route that the user is currently on, and returns a tuple
  -- of the 'Text' that you want the label to display, and a previous
  -- breadcrumb route.
  breadcrumb ::
    -- \| The route the user is visiting currently.
    Route App ->
    Handler (Text, Maybe (Route App))
  breadcrumb HomeR = return ("Home", Nothing)
  breadcrumb (AuthR _) = return ("Login", Just HomeR)
  breadcrumb ProfileR = return ("Profile", Just HomeR)
  breadcrumb AdminR = return ("Admin", Just HomeR)
  breadcrumb AdminPageviewsR = return ("Admin/Pageviews", Just HomeR)
  breadcrumb ParthomeR = return ("Home", Just HomeR)
  breadcrumb PartnewR = return ("Posts/newr", Just HomeR)
  breadcrumb PartadminR = return ("Adminr", Just HomeR)
  breadcrumb PartprofileR = return ("Profiles", Just HomeR)
  breadcrumb PostNewR = return ("Posts/new", Just HomeR)
  breadcrumb (PostDetailsR idx) = return ("Posts/" ++ toPathPiece idx, Just HomeR)
  breadcrumb (PartdetailsR idx) = return ("Posts/" ++ toPathPiece idx, Just HomeR)
  breadcrumb _ = return ("home", Nothing)

-- How to run database actions.
instance YesodPersist App where
  type YesodPersistBackend App = SqlBackend
  runDB :: SqlPersistT Handler a -> Handler a
  runDB action = do
    master <- getYesod
    runSqlPool action $ appConnPool master

instance YesodPersistRunner App where
  getDBRunner :: Handler (DBRunner App, Handler ())
  getDBRunner = defaultGetDBRunner appConnPool

instance YesodAuth App where
  type AuthId App = UserId

  -- Where to send a user after successful login
  loginDest :: App -> Route App
  loginDest _ = HomeR

  -- Where to send a user after logout
  logoutDest :: App -> Route App
  logoutDest _ = HomeR

  -- Override the above two destinations when a Referer: header is present
  redirectToReferer :: App -> Bool
  redirectToReferer _ = False

  authenticate ::
    (MonadHandler m, HandlerSite m ~ App) =>
    Creds App ->
    m (AuthenticationResult App)
  authenticate creds = liftHandler $
    runDB $ do
      x <- getBy $ UniqueUser $ credsIdent creds
      -- liftIO $ putStrLn $ pack $ show creds
      case x of
        Just (Entity uid _) -> return $ Authenticated uid
        Nothing ->
          Authenticated
            <$> insert
              User
                { userIdent = credsIdent creds,
                  userPassword = Nothing
                }

  -- You can add other plugins like Google Email, email or OAuth here

  authPlugins :: App -> [AuthPlugin App]
  authPlugins app =
    [ authOpenId Claimed [],
      Google.oauth2Google clientId clientSecret
    ]
      ++ extraAuthPlugins
    where
      -- Enable authDummy login if enabled.
      extraAuthPlugins = [authDummy | appAuthDummyLogin $ appSettings app]

-- | Access function to determine if a user is logged in.
isAuthenticated :: Handler AuthResult
isAuthenticated = do
  -- maid <- lookupSession "_ID"
  -- liftIO $ putStrLn $ maybe "" id (maid)
  -- liftIO $ putStrLn $ pack $ show maid
  muid <- maybeAuthId
  return $ case muid of
    Nothing -> Unauthorized "You must login to access this page"
    Just _ -> Authorized

instance YesodAuthPersist App

-- This instance is required to use forms. You can modify renderMessage to
-- achieve customized and internationalized form validation messages.
instance RenderMessage App FormMessage where
  renderMessage :: App -> [Lang] -> FormMessage -> Text
  renderMessage _ _ = defaultFormMessage

-- Useful when writing code that is re-usable outside of the Handler context.
-- An example is background jobs that send email.
-- This can also be useful for writing code that works across multiple Yesod applications.
instance HasHttpManager App where
  getHttpManager :: App -> Manager
  getHttpManager = appHttpManager

unsafeHandler :: App -> Handler a -> IO a
unsafeHandler = Unsafe.fakeHandlerGetLogger appLogger

instance YesodChat App where
  getUserName = do
    muser <- maybeAuthPair
    case muser of
      Nothing -> do
        setMessage "Not logged in"
        redirect $ AuthR LoginR
      Just (_, user) -> return $ userIdent user
  isLoggedIn = isJust <$> maybeAuthId

-- Note: Some functionality previously present in the scaffolding has been
-- moved to documentation in the Wiki. Following are some hopefully helpful
-- links:
--
-- https://github.com/yesodweb/yesod/wiki/Sending-email
-- https://github.com/yesodweb/yesod/wiki/Serve-static-files-from-a-separate-domain
-- https://github.com/yesodweb/yesod/wiki/i18n-messages-in-the-scaffolding
