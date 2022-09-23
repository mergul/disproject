{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

module Chat.Data where

import Blaze.ByteString.Builder.Char.Utf8 (fromText)
import Control.Concurrent.Chan
import Data.Monoid ()
import Data.Text (Text)
import Network.Wai.EventSource
import Yesod
import Yesod.Core.Types ()

-- | Our subsite foundation. We keep a channel of events that all connections
-- will share.
newtype Chat = Chat (Chan ServerEvent)

-- | We need to know how to check if a user is logged in and how to get
-- his/her username (for printing messages).
class
  (Yesod master, RenderMessage master FormMessage) =>
  YesodChat master
  where
  getUserName :: HandlerFor master Text
  isLoggedIn :: HandlerFor master Bool

type ChatHandler a =
  forall master.
  YesodChat master =>
  SubHandlerFor Chat master a

-- Now we set up our subsite. The first argument is the subsite, very similar
-- to how we've used mkYesod in the past. The second argument is specific to
-- subsites. What it means here is "the master site must be an instance of
-- YesodChat".
--
-- We define two routes: a route for sending messages from the client to the
-- server, and one for opening up the event stream to receive messages from
-- the server.
mkYesodSubData
  "Chat"
  [parseRoutes|
/send SendR POST
/recv ReceiveR GET
|]

-- | Get a message from the user and send it to all listeners.
postSendR :: ChatHandler ()
postSendR = do
  from <- liftHandler getUserName

  -- Note that we're using GET parameters for simplicity of the Ajax code.
  -- This could easily be switched to POST. Nonetheless, our overall
  -- approach is still RESTful since this route can only be accessed via a
  -- POST request.
  body <- runInputGet $ ireq textField "message"

  -- Get the channel
  Chat chan <- getSubYesod

  -- Send an event to all listeners with the user's name and message.
  liftIO $
    writeChan chan $
      ServerEvent Nothing Nothing $
        return $
          fromText from <> fromText ": " <> fromText body

-- | Send an eventstream response with all messages streamed in.
getReceiveR :: ChatHandler ()
getReceiveR = do
  -- First we get the main channel
  Chat chan0 <- getSubYesod
  chan <- liftIO $ dupChan chan0

  -- Now we use the event source API. eventSourceAppChan takes two parameters:
  -- the channel of events to read from, and the WAI request. It returns a
  -- WAI response, which we can return with sendWaiResponse.
  sendWaiApplication $ eventSourceAppChan chan
