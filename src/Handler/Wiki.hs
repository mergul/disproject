{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Handler.Wiki where

import qualified Data.Map as Map
import qualified Data.Text.Lazy as TL
import Import
import Text.Julius ()
import Text.Markdown

wikiForm :: Maybe Textarea -> Html -> MForm Handler (FormResult Textarea, Widget)
wikiForm mtext = renderDivs $ areq textareaField "Page body" mtext

-- Show a wiki page and an edit form
getWikiR :: [Text] -> Handler Html
getWikiR page = do
  -- Get the reference to the contents map
  icontent <- fmap appWikiContent getYesod

  -- And read the map from inside the reference
  content <- liftIO $ readIORef icontent

  -- Lookup the contents of the current page, if available
  let mtext = lookup page content

  -- Generate a form with the current contents as the default value.
  -- Note that we use the Textarea wrapper to get a <textarea>.
  (form, _) <- generateFormPost $ wikiForm $ fmap Textarea mtext
  defaultLayout $ do
    case mtext of
      -- We're treating the input as markdown. The markdown package
      -- automatically handles XSS protection for us.
      Just text -> toWidget $ markdown def $ TL.fromStrict text
      Nothing -> do
        [whamlet|
            <h2>Edit page
            <form method=post>
                ^{form}
                <div>
                    <input type=submit>
        |]
        toWidget
          [lucius|
              form > div {
                  display: grid;
                  justify-content: center;
                  color: white;
              }
              input {
                  max-height: 40px;
              }
            |]

-- Get a submitted wiki page and updated the contents.
postWikiR :: [Text] -> Handler Html
postWikiR page = do
  icontent <- fmap appWikiContent getYesod
  content <- liftIO $ readIORef icontent
  let mtext = lookup page content
  ((res, form), _) <- runFormPost $ wikiForm $ fmap Textarea mtext
  case res of
    FormSuccess (Textarea t) -> do
      liftIO $
        atomicModifyIORef icontent $
          \m -> (Map.insert page t m, ())
      setMessage "Page updated"
      redirect $ WikiR page
    _ ->
      defaultLayout
        [whamlet|
                    <form method=post>
                        ^{form}
                        <div>
                            <input type=submit>
                |]