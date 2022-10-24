{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Handler.FirstCustomer where

import Data.Aeson
import Data.Aeson.TH
import Foundation (Handler)
import Yesod

data Customer = Customer
  { userId :: Int,
    userFirstName :: String,
    userLastName :: String
  }
  deriving (Eq, Show)

$(deriveJSON defaultOptions ''Customer)

instance {-# OVERLAPPABLE #-} (ToJSON a) => ToContent a where
  toContent = toContent . toJSON

instance {-# OVERLAPPABLE #-} (ToJSON a) => ToTypedContent a where
  toTypedContent = TypedContent typeJson . toContent

getCustomersR :: Handler [Customer]
getCustomersR =
  return
    [ Customer 1 "Isaac" "Newton",
      Customer 2 "Albert" "Einstein"
    ]

getFirstCustomerR :: Handler Customer
getFirstCustomerR = head <$> getCustomersR