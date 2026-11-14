//Use this file to add translations for this theme

var dictionaries = {
    it: {
        "Feed": "Feed",
        "Store": "App Store",
        "Gallery": "Galleria",
        "Files": "File",
        "Suspend": "Sospendi",
        "Theme Settings": "Impostazioni del Tema",
        "All Software": "Tutti i giochi",
        "All": "Tutti",
        "Search": "Cerca",
        "No software": "Nessun gioco",
        "No results for \"%1\"": "Nessun risultato per \"%1\"",
        "By Time Last Played": "Per ultimo avvio",
        "By Total Play Time": "Per tempo di gioco",
        "By Title": "Per titolo",
        "By Publisher": "Per Publisher",
        "Favorites": "Preferiti",
        "Back": "Indietro",
        "Details": "Dettagli",
        "Fav": "Pref.",
        "Next Collection": "Collezione succ.",
        "Prev Collection": "Collezione prec.",
        "Play": "Gioca",
        "Description": "Descrizione",
        "Trophies": "Trofei",
        "Loading...": "Caricamento...",
        "Who's using the software?": "Chi sta giocando?",
        "New profile": "Nuovo profilo",
        "Edit profile": "Modifica profilo",
        "Username": "Nome utente",
        "Choose image": "Scegli immagine",
        "Change image": "Cambia immagine",
        "Change username": "Cambia nome utente",
        "Delete profile": "Elimina profilo",
        "Create": "Crea",
        "Enter a username": "Inserisci un nome utente",
        "Choose an image": "Scegli un'immagine",
        "Delete \"%1\"?": "Eliminare \"%1\"?",
        "This profile will be removed": "Il profilo verrà rimosso",
        "Hide \"%1\"?": "Nascondere \"%1\"?",
        "Show \"%1\" again?": "Mostrare di nuovo \"%1\"?",
        "It won't appear on the home screen anymore": "Non comparirà più nella schermata iniziale",
        "It will appear on the home screen again": "Comparirà di nuovo nella schermata iniziale",
        "General": "Generale",
        "Home Screen": "Schermata iniziale",
        "Buttons Settings": "Impostazioni pulsanti",
        "Advanced Settings": "Impostazioni avanzate",
        "Language": "Lingua",
        "Yes": "Sì",
        "Open": "Apri"
    }
};

function translate(lang, text, arg) {
    var dict = dictionaries[lang];
    var result = (dict && dict[text] !== undefined) ? dict[text] : text;
    if (arg !== undefined)
        result = result.replace("%1", arg);
    return result;
}