module Request exposing (Request, decode)

import Dict exposing (Dict)
import Json.Decode exposing (Decoder)
import Time


type alias Request =
    { time : Time.Posix
    , method : String
    , body : Maybe String
    , url : String
    , headers : Dict String String
    , elmJs : String
    }



-- Decoding


decode : Decoder Request
decode =
    Json.Decode.map6 Request
        (Json.Decode.field "time" decodePosix)
        (Json.Decode.field "method" Json.Decode.string)
        (Json.Decode.field "body" (Json.Decode.maybe Json.Decode.string))
        (Json.Decode.field "url" Json.Decode.string)
        (Json.Decode.field "headers" (Json.Decode.dict Json.Decode.string))
        (Json.Decode.field "elmJs" Json.Decode.string)


decodePosix : Decoder Time.Posix
decodePosix =
    Json.Decode.map Time.millisToPosix Json.Decode.int
