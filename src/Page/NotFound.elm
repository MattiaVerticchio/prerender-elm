module Page.NotFound exposing (Model, Msg, head, init, update, view)

import Html.String as Html
import Html.String.Attributes exposing (href)
import Request exposing (Request)
import Shared
import Status
import View exposing (View)



-- Head


head : Request -> List tag
head _ =
    []



-- Init


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )



-- Update


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- View


view : Shared.Model -> Model -> View Msg
view _ _ =
    { title = "404"
    , status = Status.NotFound
    , body =
        [ Html.h1 [] [ Html.text "Page not found" ]
        , Html.a [ href "/" ] [ Html.text "Go to home" ]
        ]
    }
