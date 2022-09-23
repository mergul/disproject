{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
module Handler.PostNew where

import Import
import Yesod.Text.Markdown
import Yesod.Form.Bootstrap3 (BootstrapFormLayout (..), renderBootstrap3, bfs)

blogPostForm :: AForm Handler BlogPost
blogPostForm =  BlogPost
    <$> areq textField (bfs ("Title" :: Text)) Nothing
    <*> areq markdownField (bfs ("Article" :: Text)) Nothing

getPostNewR :: Handler Html
getPostNewR = do 
    (widget, enctype) <- generateFormPost $ renderBootstrap3 BootstrapBasicForm  blogPostForm
    defaultLayout $ do 
        $(widgetFile "posts/new")

postPostNewR :: Handler Html
postPostNewR = do
    ((result, widget), enctype) <- runFormPost $ renderBootstrap3 BootstrapBasicForm  blogPostForm
    case result of
        FormSuccess blogPost -> do
            blogPostId <- runDB $ insert blogPost
            redirect $ PostDetailsR blogPostId
        _ -> defaultLayout $ do
            $(widgetFile "posts/new")