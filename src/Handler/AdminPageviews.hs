{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-deferred-out-of-scope-variables #-}

module Handler.AdminPageviews where

import Import
import Text.Julius ()

getAdminPageviewsR :: Handler Html
getAdminPageviewsR = do
  (_, _) <- requireAuthPair
  defaultLayout $ do
    addScript $ StaticR js_mychart_js
    $(widgetFile "admin/sidebar")
    $(widgetFile "admin/pageviews")