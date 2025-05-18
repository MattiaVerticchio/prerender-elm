module Shared exposing (Model, Msg(..), init, update, updateWithData)

import Data exposing (Data)



-- Init


type alias Model =
    { n : Int }


init : ( Model, Cmd Msg )
init =
    ( { n = 0 }, Cmd.none )



-- Update


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


updateWithData : Data -> Model -> Model
updateWithData data model =
    { model | n = data }
