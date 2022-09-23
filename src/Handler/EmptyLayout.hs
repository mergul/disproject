{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Handler.EmptyLayout where

import Import
import Text.Hamlet (hamletFile)
import Text.Julius ()

emptyLayout :: Widget -> Handler Html
emptyLayout widget = do
  pc <- widgetToPageContent $ do
    $(widgetFile "empty-layout")
  withUrlRenderer $(hamletFile "./templates/empty-layout-wrapper.hamlet")
