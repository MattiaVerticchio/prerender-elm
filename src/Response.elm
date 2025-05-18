port module Response exposing (Init, Response, send)

import Headers exposing (Headers)
import Json.Encode exposing (Value)


type alias Response =
    { document : String
    , init : Init
    }


type alias Init =
    { status : Int
    , headers : Headers
    }



-- Ports


port sendResponse : Value -> Cmd msg


send : Response -> Cmd msg
send response =
    sendResponse <|
        Json.Encode.object
            [ ( "document", Json.Encode.string response.document )
            , ( "init"
              , Json.Encode.object
                    [ ( "status", Json.Encode.int response.init.status )
                    , ( "headers", Headers.encode response.init.headers )
                    ]
              )
            ]
