{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Handler.Partprofile where

import Handler.EmptyLayout (emptyLayout)
import Import

getPartprofileR :: Handler Html
getPartprofileR = do
  (_, user) <- requireAuthPair
  emptyLayout $ do
    setTitle . toHtml $ userIdent user <> "'s User page"
    $(widgetFile "profile")
