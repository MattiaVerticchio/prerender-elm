module Route exposing (Route(..), fromString, fromUrl, toString)

import AppUrl
import Url exposing (Url)


type Route
    = Index


toString : Route -> String
toString route =
    case route of
        Index ->
            "/"



-- Offerte ->
--     "/offerte"
-- Offerta _ ->
--     "/offerta"
-- Faq ->
--     "/faq"


fromUrl : Url -> Maybe Route
fromUrl url =
    fromPath (AppUrl.fromUrl url).path


fromString : String -> Maybe Route
fromString string =
    case Url.fromString string of
        Just url ->
            fromPath (AppUrl.fromUrl url).path

        _ ->
            Nothing


fromPath : List String -> Maybe Route
fromPath path =
    case path of
        [] ->
            Just Index

        -- [ "offerte" ] ->
        --     Just Offerte
        -- "offerta" :: rest ->
        --     makeOfferta rest ""
        -- [ "faq" ] ->
        --     Just Faq
        _ ->
            Nothing



-- makeOfferta : List String -> String -> Maybe Route
-- makeOfferta remaining acc =
--     case remaining of
--         [] ->
--             Just (Offerta acc)
--         x :: rest ->
--             makeOfferta rest (acc ++ "/" ++ x)
