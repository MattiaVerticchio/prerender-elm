module Headers exposing (Headers, encode)

import Dict exposing (Dict)
import Json.Encode exposing (Value)


type alias Headers =
    Dict String String


encode : Headers -> Value
encode =
    Json.Encode.dict (\x -> x) Json.Encode.string
