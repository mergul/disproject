{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Handler.Partadmin where

import Handler.EmptyLayout (emptyLayout)
import Import
import Text.Julius ()

getPartadminR :: Handler Html
getPartadminR = do
  (_, _) <- requireAuthPair
  emptyLayout $ do
    $(widgetFile "admin/sidebar")
    $(widgetFile "admin/index")