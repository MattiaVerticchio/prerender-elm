module Page.Index exposing (Model, Msg, head, init, update, view)

import Data exposing (Data)
import Html.String as Html exposing (Html)
import Html.String.Events as Events
import Request exposing (Request)
import Shared
import Status
import View exposing (View)



-- Head


head : Data -> Request -> List (Html msg)
head _ _ =
    []



-- Init


type alias Model =
    { n : Int }


init : Shared.Model -> ( Model, Cmd Msg )
init shared =
    ( { n = shared.n }, Cmd.none )



-- Update


type Msg
    = NoOp
    | Plus
    | Minus


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Plus ->
            ( { model | n = model.n + 1 }, Cmd.none )

        Minus ->
            ( { model | n = model.n - 1 }, Cmd.none )



-- View


view : Shared.Model -> Model -> View Msg
view _ model =
    { title = "Index page"
    , status = Status.Ok
    , body =
        [ Html.text "Counter: "
        , Html.text (String.fromInt model.n)
        , Html.button [ Events.onClick Plus ] [ Html.text "+" ]
        , Html.button [ Events.onClick Minus ] [ Html.text "-" ]
        ]
    }
