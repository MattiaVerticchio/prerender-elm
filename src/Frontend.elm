module Frontend exposing (initWithData, main, viewWithData)

import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation exposing (Key)
import Data exposing (Data)
import Json.Decode exposing (Value)
import Page.Index
import Page.NotFound
import Route exposing (Route(..))
import Shared
import Url exposing (Url)
import View exposing (View)



-- Main


main : Program Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }



-- Init


type alias Model =
    { key : Key
    , subModel : ModelWithData
    }


type alias ModelWithData =
    { shared : Shared.Model
    , page : PageModel
    }


type PageModel
    = IndexModel Page.Index.Model
    | NotFoundModel Page.NotFound.Model


init : Value -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    case Data.decode flags of
        Err _ ->
            let
                ( sharedModel, sharedMsg ) =
                    Shared.init

                ( pageModel, pageMsg ) =
                    initPage sharedModel url
            in
            ( { key = key
              , subModel =
                    { shared = sharedModel
                    , page = pageModel
                    }
              }
            , Cmd.batch [ Cmd.map FromShared sharedMsg, pageMsg ]
            )

        Ok data ->
            let
                sub =
                    initWithData data url
            in
            ( { key = key
              , subModel = sub.model
              }
            , sub.msg
            )


initWithData : Data -> Url -> { model : ModelWithData, msg : Cmd Msg }
initWithData data url =
    let
        ( sharedModel, sharedMsg ) =
            Shared.init

        sharedWithData =
            Shared.updateWithData data sharedModel

        ( pageModel, pageMsg ) =
            initPage sharedWithData url
    in
    { model = { shared = sharedWithData, page = pageModel }
    , msg = Cmd.batch [ Cmd.map FromShared sharedMsg, pageMsg ]
    }


initPage : Shared.Model -> Url -> ( PageModel, Cmd Msg )
initPage shared url =
    case Route.fromUrl url of
        Nothing ->
            let
                ( pageModel, pageCmd ) =
                    Page.NotFound.init
            in
            ( NotFoundModel pageModel, Cmd.map (FromNotFound >> FromPage) pageCmd )

        Just route ->
            case route of
                Index ->
                    let
                        ( pageModel, pageMsg ) =
                            Page.Index.init shared
                    in
                    ( IndexModel pageModel, Cmd.map (FromIndex >> FromPage) pageMsg )



-- Update


type Msg
    = OnUrlRequest Browser.UrlRequest
    | OnUrlChange Url
    | FromShared Shared.Msg
    | FromPage PageMsg


type PageMsg
    = FromIndex Page.Index.Msg
    | FromNotFound Page.NotFound.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ subModel } as model) =
    case msg of
        OnUrlRequest (Internal url) ->
            ( model, Browser.Navigation.pushUrl model.key (Url.toString url) )

        OnUrlRequest (External url) ->
            ( model, Browser.Navigation.load url )

        OnUrlChange url ->
            let
                ( pageModel, pageCmd ) =
                    initPage subModel.shared url
            in
            ( { model | subModel = { subModel | page = pageModel } }, pageCmd )

        FromShared sharedMsg ->
            let
                ( sharedModel, sharedCmd ) =
                    Shared.update sharedMsg subModel.shared
            in
            ( { model | subModel = { subModel | shared = sharedModel } }
            , Cmd.map FromShared sharedCmd
            )

        FromPage pageMsg ->
            let
                ( pageModel, pageCmd ) =
                    pageUpdate pageMsg subModel.page
            in
            ( { model | subModel = { subModel | page = pageModel } }, pageCmd )


pageUpdate : PageMsg -> PageModel -> ( PageModel, Cmd Msg )
pageUpdate pageMsg pageModel =
    case ( pageMsg, pageModel ) of
        ( FromIndex msg, IndexModel model ) ->
            let
                ( indexModel, indexCmd ) =
                    Page.Index.update msg model
            in
            ( IndexModel indexModel, Cmd.map (FromIndex >> FromPage) indexCmd )

        ( FromNotFound msg, NotFoundModel model ) ->
            let
                ( newModel, newCmd ) =
                    Page.NotFound.update msg model
            in
            ( NotFoundModel newModel, Cmd.map (FromNotFound >> FromPage) newCmd )

        _ ->
            ( pageModel, Cmd.none )



-- View


view : Model -> Document Msg
view model =
    View.toDocument (viewWithData model.subModel)


viewWithData : ModelWithData -> View Msg
viewWithData model =
    case model.page of
        IndexModel pageModel ->
            Page.Index.view model.shared pageModel
                |> View.map (FromIndex >> FromPage)

        NotFoundModel pageModel ->
            Page.NotFound.view model.shared pageModel
                |> View.map (FromNotFound >> FromPage)



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
