module View exposing (..)

import Browser exposing (Document)
import Html.String as Html exposing (Html)
import Status exposing (Status)


type alias View msg =
    { title : String
    , status : Status
    , body : List (Html msg)
    }


map : (a -> b) -> View a -> View b
map f view =
    { title = view.title
    , status = view.status
    , body = List.map (Html.map f) view.body
    }


toDocument : View msg -> Document msg
toDocument view =
    { title = view.title
    , body = List.map Html.toHtml view.body
    }
