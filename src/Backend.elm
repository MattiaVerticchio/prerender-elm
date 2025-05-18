module Backend exposing (..)

import Data
import Dict
import Frontend
import Html.String as Html exposing (Html)
import Html.String.Attributes as Attr
import Json.Decode
import Json.Encode exposing (Value)
import Page.Index
import Page.NotFound
import Request exposing (Request)
import Response exposing (Response)
import Route exposing (Route(..))
import Status
import Url exposing (Url)
import View exposing (View)


main : Program Value () ()
main =
    Platform.worker
        { init = \flags -> ( (), Response.send (initServer flags) )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


initServer : Value -> Response
initServer value =
    case Json.Decode.decodeValue Request.decode value of
        Err error ->
            viewToResponse Nothing
                0
                []
                { title = "Bad request"
                , status = Status.BadRequest
                , body =
                    [ Html.h1 [] [ Html.text "Bad request" ]
                    , Html.span [] [ Html.text (Json.Decode.errorToString error) ]
                    ]
                }

        Ok request ->
            let
                data =
                    42
            in
            case Url.fromString request.url of
                Nothing ->
                    viewToResponse (Just request.elmJs)
                        data
                        []
                        { title = "Bad request"
                        , status = Status.BadRequest
                        , body =
                            [ Html.h1 [] [ Html.text "Bad request" ]
                            , Html.span [] [ Html.text "Invalid URL" ]
                            ]
                        }

                Just url ->
                    let
                        head =
                            initWithHead data request url
                    in
                    Frontend.initWithData data url
                        |> .model
                        |> Frontend.viewWithData
                        |> viewToResponse (Just request.elmJs) data head


initWithHead : Data.Data -> Request -> Url -> List (Html msg)
initWithHead data request url =
    case Route.fromUrl url of
        Nothing ->
            Page.NotFound.head request

        Just page ->
            case page of
                Index ->
                    Page.Index.head data request


viewToResponse : Maybe String -> Data.Data -> List (Html msg) -> View msg -> Response
viewToResponse elmJs data head { title, status, body } =
    let
        viewDocument : Html msg
        viewDocument =
            Html.node "html" [ Attr.lang "it" ] [ viewHead, viewBody ]

        viewHead : Html msg
        viewHead =
            Html.node "head" [] (viewCharset :: viewViewport :: viewTitle :: viewRestOfHead)

        viewBody : Html msg
        viewBody =
            Html.node "body" [] (body ++ [ viewData ])

        viewCharset : Html msg
        viewCharset =
            Html.node "meta" [ Attr.attribute "charset" "utf-8" ] []

        viewViewport : Html msg
        viewViewport =
            Html.node "meta"
                [ Attr.name "viewport"
                , Attr.attribute "content" "width=device-width, initial-scale=1"
                ]
                []

        viewTitle : Html msg
        viewTitle =
            Html.node "title" [] [ Html.text title ]

        viewRestOfHead : List (Html msg)
        viewRestOfHead =
            case elmJs of
                Nothing ->
                    head

                Just url ->
                    Html.node "link" [ Attr.href url, Attr.rel "modulepreload" ] []
                        :: Html.node "script" [ Attr.src url, Attr.type_ "module" ] []
                        :: head

        viewData : Html msg
        viewData =
            Html.node "script"
                [ Attr.type_ "application/json"
                , Attr.id "injected-data"
                ]
                [ Data.encode data |> Json.Encode.encode 0 |> Html.text ]
    in
    { document = "<!DOCTYPE html>" ++ Html.toString 0 viewDocument
    , init =
        { status = Status.toCode status
        , headers = Dict.singleton "content-type" "text/html;charset=UTF-8"
        }
    }
