{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-deferred-out-of-scope-variables #-}

module Handler.Partadmin where

import Handler.EmptyLayout (emptyLayout)
import Import
import Text.Julius ()

getPartadminR :: Handler Html
getPartadminR = do
  (_, _) <- requireAuthPair
  emptyLayout $ do
    addScript $ StaticR js_mychart_js
    $(widgetFile "admin/sidebar")
    $(widgetFile "admin/index")