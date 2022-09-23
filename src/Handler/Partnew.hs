{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Handler.Partnew where

import Handler.EmptyLayout (emptyLayout)
import Import
import Yesod.Form.Bootstrap3 (BootstrapFormLayout (..), bfs, renderBootstrap3)
import Yesod.Text.Markdown

blogPostForm :: AForm Handler BlogPost
blogPostForm =
  BlogPost
    <$> areq textField (bfs ("Title" :: Text)) Nothing
    <*> areq markdownField (bfs ("Article" :: Text)) Nothing

getPartnewR :: Handler Html
getPartnewR = do
  (widget, enctype) <- generateFormPost $ renderBootstrap3 BootstrapBasicForm blogPostForm
  emptyLayout $ do
    $(widgetFile "posts/new")
