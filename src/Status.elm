module Status exposing (Status(..), toCode)


type Status
    = Ok
    | BadRequest
    | NotFound
    | InternalServerError


toCode : Status -> Int
toCode status =
    case status of
        Ok ->
            200

        BadRequest ->
            400

        NotFound ->
            404

        InternalServerError ->
            500
