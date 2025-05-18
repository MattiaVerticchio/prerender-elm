module Data exposing (Data, decode, encode)

import Json.Encode exposing (Value)
import Serialize exposing (Error)


type alias Data =
    Int


codec : Serialize.Codec e Data
codec =
    Serialize.int


encode : Data -> Value
encode value =
    Serialize.encodeToJson codec value


decode : Value -> Result (Error e) Data
decode value =
    Serialize.decodeFromJson codec value
