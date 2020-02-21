module Main exposing (Event, Model, Msg(..), Person, attendanceDecoder, dummyData, eventDisplayNames, groupByEvent, init, main, noMsg, update, view)

import Browser
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (checked, style, type_)
import Html.Events exposing (onCheck, onClick)
import Http
import Json.Decode as D
import Json.Encode as E
import Set exposing (Set)


type alias Person =
    String


type alias Event =
    String


type alias Events =
    Dict ( Person, Event ) Bool


type SubmitStatus
    = NotSubmitted
    | Submitting
    | SubmitSuccess
    | TryAgain


type alias Model =
    { submitStatus : SubmitStatus, events : Events }


eventDisplayNames =
    [ ( "mehndi", "Mehndi" )
    , ( "civil", "Civil Ceremony" )
    , ( "haldi", "Haldi" )
    , ( "reception", "Reception" )
    , ( "temple", "Hindu Wedding" )
    ]


{-| Json has the structure of

[
{name: "Kurren Nischal", email: "kurren\_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", haldi: "TRUE"}
, {name: "Mohan Nischal", email: "kurren\_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", haldi: "TRUE"}
, {name: "Neelam Nischal", email: "kurren\_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", haldi: "TRUE"}
, {name: "Grandpa", email: "kurren\_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", haldi: "TRUE"}
][
{name: "Kurren Nischal", email: "kurren_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", haldi: "TRUE"}
, {name: "Mohan Nischal", email: "kurren_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", haldi: "TRUE"}
, {name: "Neelam Nischal", email: "kurren_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", haldi: "TRUE"}
, {name: "Grandpa", email: "kurren_n@hotmail.com", mehndi: "TRUE", civil: "TRUE", haldi: "TRUE"}
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
        |> Model NotSubmitted
        |> noMsg


type Msg
    = Toggle ( Person, Event )
    | ToggleSelectAll
    | Submit
    | Submitted (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Toggle invite ->
            { submitStatus = model.submitStatus
            , events = Dict.update invite (Maybe.map not) model.events
            }
                |> noMsg

        ToggleSelectAll ->
            let
                newValue =
                    not <| allSelected model.events

                newEvents =
                    model.events
                        |> Dict.keys
                        |> List.map (\k -> ( k, newValue ))
                        |> Dict.fromList
            in
            { submitStatus = model.submitStatus, events = newEvents }
                |> noMsg

        Submit ->
            Tuple.pair
                { submitStatus = Submitting, events = model.events }
                (submitRequest model.events)

        Submitted res ->
            (case res of
                Ok () ->
                    { submitStatus = SubmitSuccess, events = model.events }

                Err _ ->
                    { submitStatus = TryAgain, events = model.events }
            )
                |> noMsg


allSelected : Dict a Bool -> Bool
allSelected d =
    d
        |> Dict.values
        |> List.all identity


dummyData =
    [ ( "Kurren Nischal", "civil" )
    , ( "Kurren Nischal", "haldi" )
    , ( "Kurren Nischal", "temple" )
    , ( "Kurren Nischal", "mehndi" )
    , ( "Kurren Nischal", "reception" )
    , ( "Mohan Nischal", "mehndi" )
    , ( "Mohan Nischal", "civil" )
    , ( "Mohan Nischal", "haldi" )
    , ( "Mohan Nischal", "temple" )
    , ( "Mohan Nischal", "reception" )
    , ( "Neelam Nischal", "mehndi" )
    , ( "Neelam Nischal", "civil" )
    , ( "Neelam Nischal", "haldi" )
    , ( "Neelam Nischal", "temple" )
    , ( "Neelam Nischal", "reception" )
    , ( "Grandpa", "mehndi" )
    , ( "Grandpa", "civil" )
    , ( "Grandpa", "haldi" )
    , ( "Grandpa", "temple" )
    , ( "Grandpa", "reception" )
    ]


groupByEvent : Events -> List ( Event, List ( Person, Bool ) )
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
        btnText =
            case model.submitStatus of
                NotSubmitted ->
                    "Submit"

                Submitting ->
                    "Submitting..."

                SubmitSuccess ->
                    "Success"

                TryAgain ->
                    "Try Again"

        disabledAttr =
            Html.Attributes.disabled (model.submitStatus == Submitting)

        events =
            model.events
                |> groupByEvent
                |> List.map (viewEvent disabledAttr)
                |> div []
    in
    div [ disabledAttr ]
        [ text "Select all"
        , input [ disabledAttr, Html.Attributes.type_ "checkbox", checked <| allSelected model.events, onCheck (always ToggleSelectAll) ] []
        , br [] []
        , events
        , br [] []
        , button [ disabledAttr, onClick Submit ] [ text btnText ]
        ]


eventDisplayNamesDict =
    Dict.fromList eventDisplayNames


viewEvent : Attribute Msg -> ( Event, List ( Person, Bool ) ) -> Html Msg
viewEvent att ( event, people ) =
    div []
        [ Dict.get event eventDisplayNamesDict |> Maybe.withDefault "" |> text
        , br [] []
        , people
            |> List.map (viewPerson att event)
            |> List.intersperse (br [] [])
            |> div [ style "margin-left" "10px" ]
        ]


viewPerson : Attribute Msg -> Event -> ( Person, Bool ) -> Html Msg
viewPerson att event ( person, attending ) =
    div []
        [ input [ att, type_ "checkbox", checked attending, onCheck <| always <| Toggle ( person, event ) ] []
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



-- HTTP


groupByPerson : Events -> List ( Person, List ( Event, Bool ) )
groupByPerson attendance =
    let
        folder ( ( person, event ), attending ) dict =
            Dict.update person (Maybe.withDefault [] >> (::) ( event, attending ) >> Just) dict
    in
    attendance
        |> Dict.toList
        |> List.foldr folder Dict.empty
        |> Dict.toList


toJson : List ( Person, List ( Event, Bool ) ) -> E.Value
toJson people =
    let
        encodeEvents events =
            events
                |> List.map (Tuple.mapSecond E.bool)
                |> E.object
    in
    people
        |> List.map (Tuple.mapSecond encodeEvents)
        |> E.object


submitRequest : Events -> Cmd Msg
submitRequest events =
    Http.post
        { url = "https://script.google.com/macros/s/AKfycbwhamnhpgOJ3RyEAom3-KF3I0UEE7GmMtSDQoPBDyqtPQAV9b2U/exec"
        , body = Http.stringBody "text/plain" (events |> groupByPerson |> toJson |> E.encode 0)
        , expect = Http.expectWhatever Submitted
        }
