module Main exposing (Event, Model, Msg(..), Person, attendanceDecoder, dummyData, eventDisplayNames, groupByEvent, init, main, noMsg, update, view)

import Browser
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (checked, style, type_)
import Html.Events exposing (onCheck, onClick)
import Json.Decode as D
import Set exposing (Set)


type alias Person =
    String


type alias Event =
    String


type alias Model =
    Dict ( Person, Event ) Bool


eventDisplayNames =
    [ ( "mehndi", "Mehndi" )
    , ( "civil", "Civil Ceremony" )
    , ( "boysHaldi", "Haldi" )
    , ( "reception", "Reception" )
    , ( "temple", "Hindu Wedding" )
    ]


{-| Json has the structure of

[
{name: "Kurren Nischal", email: "kurren\_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", boysHaldi: "TRUE"}
, {name: "Mohan Nischal", email: "kurren\_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", boysHaldi: "TRUE"}
, {name: "Neelam Nischal", email: "kurren\_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", boysHaldi: "TRUE"}
, {name: "Grandpa", email: "kurren\_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", boysHaldi: "TRUE"}
][
{name: "Kurren Nischal", email: "kurren_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", boysHaldi: "TRUE"}
, {name: "Mohan Nischal", email: "kurren_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", boysHaldi: "TRUE"}
, {name: "Neelam Nischal", email: "kurren_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", boysHaldi: "TRUE"}
, {name: "Grandpa", email: "kurren_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", boysHaldi: "TRUE"}
]

-}
attendanceDecoder : D.Decoder (List ( Person, Event ))
attendanceDecoder =
    let
        allEvents =
            eventDisplayNames |> List.map Tuple.first |> Set.fromList

        eventsAttending : D.Decoder (List String)
        eventsAttending =
            D.keyValuePairs (D.oneOf [ D.string |> D.map (\str -> str == "TRUE"), D.succeed False ])
                |> D.map (List.filter (\( event, isAttending ) -> Set.member event allEvents && isAttending))
                |> D.map (List.map Tuple.first)
    in
    D.map2 Tuple.pair (D.field "name" D.string) eventsAttending
        |> D.list
        |> D.map
            (\ps ->
                ps
                    |> List.concatMap (\( name, events_ ) -> List.map (Tuple.pair name) events_)
            )


noMsg a =
    ( a, Cmd.none )


init : D.Value -> ( Model, Cmd msg )
init json =
    D.decodeValue attendanceDecoder json
        |> Result.withDefault dummyData
        |> List.map (\i -> ( i, False ))
        |> Dict.fromList
        |> noMsg


type Msg
    = Toggle ( Person, Event )
    | Submit


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Toggle invite ->
            Dict.update invite (Maybe.map not) model |> noMsg

        Submit ->
            model |> noMsg


dummyData =
    [ ( "Kurren Nischal", "civil" ), ( "Kurren Nischal", "boysHaldi" ), ( "Kurren Nischal", "temple" ), ( "Kurren Nischal", "reception" ), ( "Mohan Nischal", "mehndi" ), ( "Mohan Nischal", "civil" ), ( "Mohan Nischal", "boysHaldi" ), ( "Mohan Nischal", "temple" ), ( "Mohan Nischal", "reception" ), ( "Neelam Nischal", "mehndi" ), ( "Neelam Nischal", "civil" ), ( "Neelam Nischal", "boysHaldi" ), ( "Neelam Nischal", "temple" ), ( "Neelam Nischal", "reception" ), ( "Grandpa", "mehndi" ), ( "Grandpa", "civil" ), ( "Grandpa", "boysHaldi" ), ( "Grandpa", "temple" ), ( "Grandpa", "reception" ) ]


groupByEvent : Dict ( Person, Event ) Bool -> List ( Event, List ( Person, Bool ) )
groupByEvent attendance =
    let
        folder ( ( person, event ), attending ) dict =
            Dict.update event (Maybe.withDefault [] >> (::) ( person, attending ) >> Just) dict
    in
    attendance
        |> Dict.toList
        |> List.foldr folder Dict.empty
        |> Dict.toList


view : Model -> Html Msg
view model =
    let
        events =
            model
                |> groupByEvent
    in
    events
        |> List.map viewEvent
        |> div []


eventDisplayNamesDict =
    Dict.fromList eventDisplayNames


viewEvent : ( Event, List ( Person, Bool ) ) -> Html Msg
viewEvent ( event, people ) =
    div []
        [ Dict.get event eventDisplayNamesDict |> Maybe.withDefault "" |> text
        , br [] []
        , people
            |> List.map (viewPerson event)
            |> List.intersperse (br [] [])
            |> div [ style "margin-left" "10px" ]
        ]


viewPerson : Event -> ( Person, Bool ) -> Html Msg
viewPerson event ( person, attending ) =
    div []
        [ input [ type_ "checkbox", checked attending, onCheck <| always <| Toggle ( person, event ) ] []
        , text person
        ]


main : Program D.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }
