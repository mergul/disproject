{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Handler.Home where

import Import
import Text.Julius ()
import Yesod.Form.Bootstrap3 ()

getHomeR :: Handler Html
getHomeR = do
  allPosts <- runDB $ selectList [] [Desc BlogPostId]

  let wikiRoot = WikiR []
  defaultLayout $ do
    setTitle "Welcome To Yesod!"
    $(widgetFile "posts/index")
