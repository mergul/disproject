{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-deferred-out-of-scope-variables #-}
{-# OPTIONS_GHC -Wno-unused-matches #-}

module Handler.Partdetails where

import Handler.EmptyLayout (emptyLayout)
import Import

getPartdetailsR :: BlogPostId -> Handler Html
getPartdetailsR blogPostId = do
  blogPost <- runDB $ get404 blogPostId
  emptyLayout $ do
    $(widgetFile "postDetails/post")
