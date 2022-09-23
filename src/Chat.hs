{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

module Chat where

import Chat.Data
  ( Chat,
    Route (..),
    YesodChat (isLoggedIn),
    getReceiveR,
    postSendR,
    resourcesChat,
  )
import Yesod
  ( ToJSON (toJSON),
    ToWidget (toWidget),
    ToWidgetBody (toWidgetBody),
    WidgetFor,
    Yesod (authRoute),
    YesodSubDispatch (..),
    getYesod,
    handlerToWidget,
    julius,
    lucius,
    mkYesodSubDispatch,
    newIdent,
    whamlet,
  )

instance YesodChat master => YesodSubDispatch Chat master where
  yesodSubDispatch = $(mkYesodSubDispatch resourcesChat)

data Person = Person {id :: Int, name :: String, email :: String} deriving (Show, Eq, Ord)

collections :: [Person]
collections = [Person 1 "Sibi" "sibi@domain.com", Person 2 "Michael" "michael@domain.com"]

chatWidget ::
  YesodChat master =>
  (Route Chat -> Route master) ->
  WidgetFor master ()
chatWidget toMaster = do
  cchat <- newIdent
  ccchat <- newIdent
  cccchat <- newIdent
  chat <- newIdent -- the containing div
  output <- newIdent -- the box containing the messages
  input <- newIdent -- input field from the user
  ili <- handlerToWidget isLoggedIn
  if ili
    then do
      [whamlet|
          <div ##{chat}>
              <h2>Chat
              <div ##{output}>
                  $forall Person _ pname pemail <- collections
                     ^{whamlet2 pname pemail}
              <input ##{input} type=text placeholder="Enter Message">
      |]
      toWidget
        [lucius|
            ##{chat} {
                position: fixed;
                top: 10em;
                right: 1em;
                z-index: 9999;
            }
            ##{output} {
                width: 200px;
                height: 300px;
                border: 1px solid #999;
                overflow: auto;
                border-radius: 10px;
                background-color: rgb(236, 240, 241, 0.6);
                opacity : 0;
            }
            ##{chat}:hover > ##{output} {
                opacity: 1;
                transition: 1s opacity ease;
            }
            ##{input} {
              background-color: rgb(136, 140, 141, 0.6);
              width: 200px;
            }
          |]
      toWidgetBody
        [julius|
            // Set up the receiving end
            var output = document.getElementById(#{toJSON output});
            var src = new EventSource("@{toMaster ReceiveR}");
            src.onmessage = function(msg) {
               // ber.next("first-chatter");
               // console.log(ber.value);
                // This function will be called for each new message.
                var p = document.createElement("p");
                p.appendChild(document.createTextNode(msg.data));
                output.appendChild(p);
                // And now scroll down within the output div so the most recent message
                // is displayed.
                output.scrollTop = output.scrollHeight;
            };

            // Set up the sending end: send a message via Ajax whenever the user hits
            // enter.
            var input = document.getElementById(#{toJSON input});
            input.onkeyup = function(event) {
                var keycode = (event.keyCode ? event.keyCode : event.which);
                if (keycode == '13') {
                    var xhr = new XMLHttpRequest();
                    var val = input.value;
                    input.value = "";
                    var params = "?message=" + encodeURI(val);
                    xhr.open("POST", "@{toMaster SendR}" + params);
                    xhr.send(null);
                }
            }
        |]
    else do
      master <- getYesod
      [whamlet|
          <p .note>
              You must be #
              $maybe ar <- authRoute master
                  <a href=@{ar}>logged in
              $nothing
                  logged in
              \ to chat.
      |]
      toWidget
        [lucius|
            .note {
                background-color: rgba(0, 0, 0, 0.4) !important
            }
          |]

whamlet2 pname pemail = [whamlet| <p>#{pemail}: #{pname} |]