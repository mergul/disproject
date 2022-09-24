{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Handler.Parthome where

import Foundation
import Handler.EmptyLayout (emptyLayout)
import Import.NoFoundation
import Text.Julius ()

getParthomeR :: Handler Html
getParthomeR = do
  allPosts <- runDB $ selectList [] [Desc BlogPostId]
  let wikiRoot = WikiR []
  emptyLayout $ do
    $(widgetFile "posts/index")