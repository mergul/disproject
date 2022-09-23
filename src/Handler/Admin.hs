{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Handler.Admin where

import Import
import Text.Julius ()

getAdminR :: Handler Html
getAdminR = do
  (_, _) <- requireAuthPair
  defaultLayout $ do
    $(widgetFile "admin/sidebar")
    $(widgetFile "admin/index")