{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Html
    ( registerPage
    , successPage
    , registrationListPage
    , registrationListPage'
    , registrationPrintPage
    , Html
    ) where

import qualified Text.Blaze.Html5              as H
import Text.Blaze.Html5 ((!), (!?))
import qualified Text.Blaze.Html5.Attributes   as A
import qualified Text.Digestive.Blaze.Html5    as DH
import qualified Text.Digestive.View           as DV
import qualified Data.Text                     as T
import Data.Monoid ((<>))
import Data.Time.Clock (UTCTime)
import Data.Time.Format (formatTime, defaultTimeLocale)
import Data.Time.LocalTime (utcToZonedTime, hoursToTimeZone, ZonedTime)
import Data.Maybe (catMaybes, fromMaybe)
import Prelude hiding (id)

import qualified IO.Db as Db
import Types
import Util
import qualified Domain.Registration as R
import qualified Domain.SharedTypes as DT

type Html = H.Html

instance H.ToMarkup DT.PaymentCode where
    toMarkup (DT.PaymentCode x) = H.toMarkup x

layout :: H.Html -> H.Html
layout inner = do
    H.docType
    H.html ! A.lang "de" $ do
        H.head $ do
            H.meta ! A.charset "utf-8"
            H.meta ! A.name "viewport" ! A.content "width=device-width, initial-scale=1, shrink-to-fit=no"
            H.title "Freiburger Convention 2019"
            H.link ! A.rel "stylesheet" ! A.type_ "text/css" ! A.href "https://stackpath.bootstrapcdn.com/bootstrap/4.1.2/css/bootstrap.min.css"
            H.link ! A.rel "stylesheet" ! A.type_ "text/css" ! A.href "https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css"
        H.body $ do
            H.div ! A.class_ "container" $ do
                H.div ! A.class_ "mb-3" $ mempty
                inner

registrationListPage' :: [R.ExistingRegistration] -> (GymSleepingLimit, CampingSleepingLimit) -> H.Html
registrationListPage' registrations (GymSleepingLimit gymSleepingLimit, CampingSleepingLimit campingLimit) = layout $ do
    let sleepovers = [] -- fmap Db.dbParticipantSleepovers registrations
    row $ do
        col 12 $ do
            H.h1 "Anmeldungen"
    row $ do
        col 12 $ do
            H.div ! A.class_ "alert alert-primary" $ do
                H.ul $ do
                    {-
                    H.li $ do
                        H.strong $ do
                            H.toHtml $ gymSleepCount sleepovers
                            " von "
                            H.toHtml $ gymSleepingLimit
                        " Übernachtungsplätze in Klassenzimmern belegt"
                    H.li $ do
                        H.strong $ do
                            H.toHtml $ campingSleepCount sleepovers
                            " von "
                            H.toHtml $ campingLimit
                        " Campingspots belegt"
                    -}
                    H.li $ do
                        H.strong $ H.toHtml $ length registrations
                        " Anmeldungen"

    row $ do
        col 12 $ do
            H.table ! A.class_ "table" $ do
                H.thead $ do
                    H.tr $ do
                        H.th "E-Mail"
                        H.th "Anzahl Teilnehmer"
                        H.th "Anmerkungen"
                        H.th "Verwendungszweck"
                        H.th "Angemeldet am"
                        H.th "Aktionen"
                H.tbody $ mapM_ registrationRow registrations
    {-row $ do
        col 3 $ do
            H.a ! A.href "/registrations.csv" $ "Download als .csv"
        col 3 $ do
            H.a ! A.href "/registrations/print" $ "Print stuff"
        -}
  where
    registrationRow :: R.ExistingRegistration -> H.Html
    registrationRow R.Registration{..} =
        H.tr $ do
            H.td $ H.toHtml email
            H.td $ H.toHtml $ length participants
            H.td $ H.toHtml $ fromMaybe "" comment
            H.td $ H.toHtml $ paymentCode
            H.td $ H.toHtml $ formatTime defaultTimeLocale "%d.%m.%Y %H:%M Uhr" $ utcToBerlin registeredAt
            H.td $ do
                H.form ! A.action (H.toValue $ "/registrations/" <> idToText id <> "/delete")  ! A.method "post" $ do
                    H.input ! A.onclick (H.toValue $ "return confirm('Willst du wirklich ' + '" <> email <> "' + ' ausladen?');") ! A.class_ "btn btn-danger" ! A.type_ "submit" ! A.name "delete" ! A.value "Löschen"
    idToText (DT.Id i) = T.pack $ show i
    gym GymSleeping = "X"
    gym _ = ""
    tent Camping = "X"
    tent _ = ""

registrationListPage :: [Db.DbParticipant] -> (GymSleepingLimit, CampingSleepingLimit) -> H.Html
registrationListPage participants (GymSleepingLimit gymSleepingLimit, CampingSleepingLimit campingLimit) = layout $ do
    let sleepovers = fmap Db.dbParticipantSleepovers participants
    row $ do
        col 12 $ do
            H.h1 "Anmeldungen"
    row $ do
        col 12 $ do
            H.div ! A.class_ "alert alert-primary" $ do
                H.ul $ do
                    H.li $ do
                        H.strong $ do
                            H.toHtml $ gymSleepCount sleepovers
                            " von "
                            H.toHtml $ gymSleepingLimit
                        " Übernachtungsplätze in Klassenzimmern belegt"
                    H.li $ do
                        H.strong $ do
                            H.toHtml $ campingSleepCount sleepovers
                            " von "
                            H.toHtml $ campingLimit
                        " Campingspots belegt"
                    H.li $ do
                        H.strong $ H.toHtml $ length participants
                        " Anmeldungen"

    row $ do
        col 12 $ do
            H.table ! A.class_ "table" $ do
                H.thead $ do
                    H.tr $ do
                        H.th "Name"
                        H.th "Geburtsdatum"
                        H.th "Adresse"
                        H.th "Übernachtung" ! A.colspan "2"
                        H.th "Angemeldet am"
                        H.th "Anmerkungen"
                        H.th "E-Mail"
                        H.th "Aktionen"
                    H.tr $ do
                        H.th ""
                        H.th ""
                        H.th ""
                        H.th ! A.class_ "text-center" $ "Klassenzimmer"
                        H.th ! A.class_ "text-center" $ "Zelt"
                        H.th ""
                        H.th ""
                        H.th ""
                        H.th ""
                H.tbody $ mapM_ participantRow participants
                H.tfoot $ do
                    H.tr $ do
                        H.th $ H.toHtml $ length participants
                        H.th ""
                        H.th ""
                        H.th ! A.class_ "text-right" $ H.toHtml $ gymSleepCount sleepovers
                        H.th ! A.class_ "text-right" $ H.toHtml $ campingSleepCount sleepovers
                        H.th ""
                        H.th ""
                        H.th ""
                        H.th ""
    row $ do
        col 3 $ do
            H.a ! A.href "/registrations.csv" $ "Download als .csv"
        col 3 $ do
            H.a ! A.href "/registrations/print" $ "Print stuff"
    H.br
    row $ do
        col 12 $ do
            H.h3 "E-Mail-Adressen der Minderjährigen"
            H.p $ do
                H.toHtml $ T.intercalate ", " $ catMaybes $ fmap Db.dbParticipantEmail $ filter (requiresParentSignature . Db.dbParticipantBirthday) participants
  where
    participantRow p@Db.DbParticipant{..} =
        H.tr $ do
            H.td $ H.toHtml dbParticipantName
            H.td $ H.toHtml $ formatDay dbParticipantBirthday
            H.td $ H.toHtml $ formatAddress p
            H.td ! A.class_ "text-center" $ gym dbParticipantSleepovers
            H.td ! A.class_ "text-center" $ tent dbParticipantSleepovers
            H.td $ H.toHtml $ formatTime defaultTimeLocale "%d.%m.%Y %H:%M Uhr" $ utcToBerlin dbParticipantRegisteredAt
            H.td $ H.toHtml $ fromMaybe "" dbParticipantComment
            H.td $ H.toHtml $ fromMaybe "" dbParticipantEmail
            H.td $ do
                H.form ! A.action (H.toValue $ "/registrations/" <> idToText dbParticipantId <> "/delete")  ! A.method "post" $ do
                    H.input ! A.onclick (H.toValue $ "return confirm('Willst du wirklich ' + '" <> dbParticipantName <> "' + ' ausladen?');") ! A.class_ "btn btn-danger" ! A.type_ "submit" ! A.name "delete" ! A.value "Löschen"
    idToText (Db.DbId i) = show i
    gym GymSleeping = "X"
    gym _ = ""
    tent Camping = "X"
    tent _ = ""

formatAddress :: Db.DbParticipant -> T.Text
formatAddress Db.DbParticipant{..} = dbParticipantStreet <> ", " <> dbParticipantPostalCode <> " " <> dbParticipantCity <> " (" <> dbParticipantCountry <> ")"

utcToBerlin :: UTCTime -> ZonedTime
utcToBerlin = utcToZonedTime (hoursToTimeZone 2)

successPage :: H.Html
successPage = layout $ do
    row $ do
        col 12 $ do
            H.h1 "Danke für deine Anmeldung!" ! A.class_ "text-center"
            H.p ! A.class_ "text-center" $ do
                "Du solltest in Kürze eine E-Mail von uns erhalten. Falls nicht, melde dich bitte unter "
                H.a ! A.href "mailto:orga@jonglieren-in-freiburg.de" $ "orga@jonglieren-in-freiburg.de"
                "."

modifiedView :: DV.View T.Text -> DV.View H.Html
modifiedView = fmap H.toHtml

alert :: T.Text -> H.Html
alert text = do
    H.div ! A.class_ "alert alert-danger" $ H.toHtml text

renderIf :: Bool -> H.Html -> H.Html
renderIf True h = h
renderIf False _ = mempty

renderUnless :: Bool -> H.Html -> H.Html
renderUnless b h = renderIf (not b) h

noSleepingMessage :: (GymSleepingLimitReached, CampingSleepingLimitReached) -> H.Html
noSleepingMessage (EnoughGymSleepingSpots, EnoughTentSpots) = mempty
noSleepingMessage (EnoughGymSleepingSpots, CampingSleepingLimitReached) = mempty
noSleepingMessage (GymSleepingLimitReached, CampingSleepingLimitReached) = alert "Leider sind schon alle Schlafplätze belegt. Du kannst dich aber trotzdem anmelden und vorbei kommen, solange du dir einen eigenen Schlafplatz organisierst."
noSleepingMessage (GymSleepingLimitReached, EnoughTentSpots) = alert "Leider sind schon alle Schlafplätze in den Klassenzimmern belegt. Du kannst dich aber trotzdem anmelden und entweder im Zelt schlafen oder dir einen eigenen Schlafplatz organisieren."

participantForm :: DV.View T.Text -> Int -> H.Html
participantForm view currentIndex = do
    row $ do
        col 12 $ do
            H.div ! A.class_ "participant" $ do
                H.br
                H.h4 $ H.toHtml $ show currentIndex ++ ". Teilnehmer"
                H.div ! A.class_ "form-group" $ do
                    label "Name" "name" view
                    DH.inputText "name" view ! A.class_ "form-control"
                    formErrorMessage "name" view
                H.div ! A.class_ "form-group" $ do
                    label "Geburtsdatum" "birthday" view
                    row $ do
                        H.div ! A.class_ "col-sm-3" $ do
                            DH.inputSelect "birthday.day" (modifiedView view) ! A.class_ "form-control"
                        H.div ! A.class_ "col-sm-5 mt-2 mt-sm-0" $ do
                            DH.inputSelect "birthday.month" (modifiedView view) ! A.class_ "form-control"
                        H.div ! A.class_ "col-sm-4 mt-2 mt-sm-0" $ do
                            DH.inputSelect "birthday.year" (modifiedView view) ! A.class_ "form-control"
                    row $ do
                        col 12 $ do
                            formErrorMessage "birthday" view
                row $ do
                    col 6 $ do
                        H.div ! A.class_ "form-group" $ do
                            label "Festivalticket" "ticket" view
                            DH.inputSelect "ticket" (modifiedView view) ! A.class_ "form-control"
                            formErrorMessage "ticket" view
                    col 6 $ do
                        H.div ! A.class_ "form-group" $ do
                            label "Unterkunft" "accommodation" view
                            DH.inputSelect "accommodation" (modifiedView view) ! A.class_ "form-control"
                            formErrorMessage "accommodation" view

jugglingRegisterForm :: DV.View T.Text -> H.Html
jugglingRegisterForm view = do
    H.form ! A.action "/register" ! A.method "post" $ do
        H.div ! A.class_ "form-group" $ do
            label' "email" view "E-Mail"
            DH.inputText "email" view ! A.class_ "form-control"
            formErrorMessage "email" view
        H.div ! A.class_ "form-group d-none" $ do
            label "Name" "botField" view
            DH.inputText "botField" view ! A.class_ "form-control"

        formErrorMessage "participants" view
        mapM_ (\(v, i) -> participantForm v i) $ DV.listSubViews "participants" view `zip` [1..]

        H.div $ do
            H.a ! A.href "#" ! A.id "link" $ do
                "Weitere Teilnehmer anmelden"
        H.br

        H.div ! A.class_ "form-group" $ do
            label "Willst du uns noch etwas mitteilen?" "comment" view
            DH.inputTextArea Nothing Nothing "comment" (modifiedView view) ! A.class_ "form-control"
            formErrorMessage "comment" view

        H.div ! A.class_ "form-group" $ do
            H.input ! A.class_ "btn btn-primary" ! A.type_ "submit" ! A.value "Anmelden"

        H.script $ do
            "var elements = document.getElementsByClassName('participant');\
            \for (var i = 1; i < elements.length; i++) {\
                \elements[i].classList.add('d-none');\
            \}\
            \var link = document.getElementById('link');\
            \link.addEventListener('click', function(e){\
                \e.preventDefault();\
                \for (var i = 1; i < elements.length; i++) {\
                \elements[i].classList.remove('d-none');\
                \}\
                \link.classList.add('d-none');\
            \})\
            \"

registerPage :: DV.View T.Text -> (GymSleepingLimitReached, CampingSleepingLimitReached) -> H.Html
registerPage view isOverLimit = layout $ do
    row $ do
        col 12 $ do
            H.h1 ! A.class_ "mb-4" $ "Anmeldung zur Freiburger Jonglierconvention 2019"
    row $ do
        col 12 $ do
            noSleepingMessage isOverLimit
            H.ul ! A.class_ "nav nav-tabs" $ do
                H.li ! A.class_ "nav-item" $ do
                    H.a ! A.class_ "nav-link active" ! A.href "#" $ "Jonglier-Convention"
                H.li ! A.class_ "nav-item" $ do
                    H.a ! A.class_ "nav-link" ! A.href "#" $ "Frisbee-Meisterschaft"
            jugglingRegisterForm view


formErrorMessage :: T.Text -> DV.View T.Text -> Html
formErrorMessage ref view =
    case DV.errors ref view of
        [] -> mempty
        es -> H.small ! A.class_ "text-danger" $ H.toHtml $ T.intercalate " " es

registrationEmail :: T.Text
registrationEmail = "herxheim.convention@gmail.com"

mailLink :: T.Text -> T.Text -> Html
mailLink text email = H.a ! A.href (H.toValue $ "mailto:" <> email) $ H.toHtml text

label :: T.Text -> T.Text -> DV.View a -> Html
label text name view =
    let ref = H.toValue $ DV.absoluteRef name view
    in
        H.label ! A.for ref $ H.toHtml text

label' :: T.Text -> DV.View a -> Html -> Html
label' name view inner =
    let ref = H.toValue $ DV.absoluteRef name view
    in
        H.label ! A.for ref $ inner

bootstrapRadios :: T.Text -> DV.View Html -> Html
bootstrapRadios ref view =
    let options = DV.fieldInputChoice ref view
        ref' = DV.absoluteRef ref view
        radio (i, c, selected) = do
            let cssId = H.toValue $ ref' <> i
            H.div ! A.class_ "form-check" $ do
                H.input ! A.id cssId ! A.class_ "form-check-input" ! A.type_ "radio" ! A.name (H.toValue ref') ! A.value (H.toValue i) !? (selected, A.checked "selected")
                H.label ! A.class_ "form-check-label" ! A.for cssId $ c
    in
        mapM_ radio options

registrationPrintPage :: [Db.DbParticipant] -> H.Html
registrationPrintPage participants = layout $ do
    row $ do
        col 12 $ do
            H.div ! A.class_ "fixed-header" $ do
                H.h1 ! A.class_ "text-center" $ "Schülerliste"
    row $ do
        col 12 $ do
            H.table ! A.class_ "table table-bordered table-sm" $ do
                H.thead $ do
                    H.tr $ do
                        H.th ! A.colspan "10" $ "Mit meiner Unterschrift nehme ich zur Kenntnis, dass die Veranstalter des 15. Pfälzer Jongliertreffens (12. - 14.10.2018) keine Haftung für Diebstahl, Sach- oder Personenschäden übernehmen können."
                    H.tr $ do
                        H.th ""
                        H.th "Name"
                        H.th "Geburtsdatum"
                        H.th "Adresse"
                        H.th "Wo?"
                        H.th ! A.style "width: 30px" $ "Fr"
                        H.th ! A.style "width: 30px" $ "Sa"
                        H.th ! A.style "width: 30px" $ "So"
                        H.th "Kosten"
                        H.th "Unterschrift"
                H.tbody $ do
                    mapM_ participantRow (zip [(1 :: Int)..] participants)
                    mapM_ emptyRow [(length participants + 1)..(length participants + 150)]

  where
    emptyRow n =
        H.tr $ do
            H.td ! A.class_ "text-right" $ H.toHtml $ show n
            H.td mempty
            H.td mempty
            H.td mempty
            H.td mempty
            H.td mempty
            H.td mempty
            H.td mempty
            H.td mempty
            H.td mempty
    participantRow (n, p@Db.DbParticipant{..}) =
        H.tr $ do
            H.td ! A.class_ "text-right" $ H.toHtml $ show n
            H.td $ H.toHtml dbParticipantName
            H.td !? (requiresParentSignature dbParticipantBirthday, A.class_ "font-weight-bold") ! A.style "width: 100px" $ H.toHtml $ formatDay dbParticipantBirthday
            H.td ! A.style "width: 300px" $ H.toHtml $ formatAddress p
            H.td ! A.class_ "text-center" ! A.style "width: 40px" $ sleepOverShort dbParticipantSleepovers
            H.td mempty
            H.td mempty
            H.td mempty
            H.td $ mempty
            H.td $ mempty
    sleepOverShort Camping = "Z"
    sleepOverShort NoNights = ""
    sleepOverShort GymSleeping = "K"
    sleepOverShort CouldntSelect = ""


row :: Html -> Html
row inner = H.div ! A.class_ "row" $ inner

col :: Int -> Html -> Html
col columns inner =
    H.div ! A.class_ (H.toValue $ "col-md-" ++ show columns) $ inner
