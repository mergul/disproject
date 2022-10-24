{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-deferred-out-of-scope-variables #-}
{-# OPTIONS_GHC -Wno-unused-matches #-}

module Handler.PostDetails where

import Import

data FileForm = FileForm
  { fileInfo :: FileInfo,
    fileDescription :: Text
  }

getPostDetailsR :: BlogPostId -> Handler Html
getPostDetailsR blogPostId = do
  blogPost <- runDB $ get404 blogPostId
  allComments <- runDB getAllComments
  defaultLayout $ do
    addScript $ StaticR js_comments_js
    let (commentFormId, commentTextareaId, commentListId) = commentIds
    aDomId <- newIdent
    $(widgetFile "postDetails/post")

postPostDetailsR :: BlogPostId -> Handler Html
postPostDetailsR blogPostId = do
  blogPost <- runDB $ get404 blogPostId
  allComments <- runDB getAllComments
  defaultLayout $ do
    let (commentFormId, commentTextareaId, commentListId) = commentIds
    aDomId <- newIdent
    $(widgetFile "postDetails/post")

commentIds :: (Text, Text, Text)
commentIds = ("js-commentForm", "js-createCommentTextarea", "js-commentList")

getAllComments :: DB [Entity Comment]
getAllComments = selectList [] [Asc CommentId]