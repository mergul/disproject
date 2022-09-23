{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Handler.AdminPageviews where

import Import
import Text.Julius ()

getAdminPageviewsR :: Handler Html
getAdminPageviewsR = do
  (_, _) <- requireAuthPair
  defaultLayout $ do
    $(widgetFile "admin/sidebar")
    $(widgetFile "admin/pageviews")