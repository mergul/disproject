{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-deferred-out-of-scope-variables #-}
{-# OPTIONS_GHC -Wno-unused-matches #-}

module Handler.Partdetails where

import Handler.EmptyLayout (emptyLayout)
import Import

data FileForm = FileForm
  { fileInfo :: FileInfo,
    fileDescription :: Text
  }

getPartdetailsR :: BlogPostId -> Handler Html
getPartdetailsR blogPostId = do
  blogPost <- runDB $ get404 blogPostId
  allComments <- runDB getAllComments
  emptyLayout $ do
    addScript $ StaticR js_comments_js
    let (commentFormId, commentTextareaId, commentListId) = commentIds
    aDomId <- newIdent
    $(widgetFile "postDetails/post")

postPartdetailsR :: BlogPostId -> Handler Html
postPartdetailsR blogPostId = do
  blogPost <- runDB $ get404 blogPostId
  allComments <- runDB getAllComments
  emptyLayout $ do
    let (commentFormId, commentTextareaId, commentListId) = commentIds
    aDomId <- newIdent
    $(widgetFile "postDetails/post")

commentIds :: (Text, Text, Text)
commentIds = ("js-commentForm", "js-createCommentTextarea", "js-commentList")

getAllComments :: DB [Entity Comment]
getAllComments = selectList [] [Asc CommentId]