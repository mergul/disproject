{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-deferred-out-of-scope-variables #-}

module Handler.Admin where

import Import
import Text.Julius ()

getAdminR :: Handler Html
getAdminR = do
  (_, _) <- requireAuthPair
  defaultLayout $ do
    addScript $ StaticR js_mychart_js
    $(widgetFile "admin/sidebar")
    $(widgetFile "admin/index")