// TODO: 1. make the RSVP form
// 2. Do the images on the home page, move on to website content

async function load() {
    // first get the guest list. Try session storage first.
    var email, guests;
    guests = sessionStorage.getItem('guests');
    if (guests) {
        guests = JSON.parse(guests);
    } else {
        displayId('loading', true);
        var guestsCsvUrl = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vTny8qvPDcrGqPOxeHYIBJKJ2tbkkNCINWy3pdHhHzt12igcxjNeX6dcHscGETDBnWlrTCOhVILEcRS/pub?gid=0&single=true&output=csv';
        var guestsStr = await makeRequest('GET', guestsCsvUrl);
        guests = parseCsv(guestsStr);
        sessionStorage.setItem('guests', JSON.stringify(guests));
    }

    email = localStorage.getItem('email');
    if (email) {
        showWebsite(email, guests);
    } else {
        // show login screen and get the email
        document.getElementById('login_submit').addEventListener('click', () => login(guests));
        displayId('loading', false);
        displayId('login', true);
    }
}

function login(guests) {
    email = document.getElementById('field_email').value;
    if (email && guests[email.toLowerCase()]) {
        localStorage.setItem('email', email);
        showWebsite(email, guests);
    } else {
        displayId('email_not_found', true);
    }
}

function showWebsite(email, guests) {

    displayId("mainContent", true);

    function removeElements(className) {
        let els = document.getElementsByClassName(className);
        while (els.length > 0) {
            els[0].remove();
        }
    }

    // show/hide stuff based on the permissions in guests
    Object.keys(translations).forEach(k => {
        var weddingEvent = translations[k];
        // if any guest under this email is invited to the event, show the page.
        var invited = guests[email.trim().toLowerCase()].some(g => {
            try {
                return g[weddingEvent].toUpperCase().trim() == "TRUE";
            } catch {
                return false;
            }
        })
        if (!invited) { removeElements(weddingEvent); }
    })

    displayId("loading", false);
    displayId("login", false);
}

function makeRequest(method, url) {
    return new Promise(function (resolve, reject) {
        let xhr = new XMLHttpRequest();
        xhr.open(method, url);
        xhr.onload = function () {
            if (this.status >= 200 && this.status < 300) {
                resolve(xhr.response);
            } else {
                reject({
                    status: this.status,
                    statusText: xhr.statusText
                });
            }
        };
        xhr.onerror = function () {
            reject({
                status: this.status,
                statusText: xhr.statusText
            });
        };
        xhr.send();
    });
}

var translations = {
    'Email': "email",
    'Invited to Boys Haldi': "haldi",
    'Invited to chunni sagan': "chunniSagan",
    'Invited to civil': "civil",
    'Invited to mehndi': "mehndi",
    'Invited to reception': "reception",
    'Invited to temple': "temple",
    'Name': "name"
}

function parseCsv(input) {


    lines = input.split('\n');
    fields = lines[0].split(',');
    var result = [];
    for (i = 1; i < lines.length; i++) {
        var obj = {};
        var line = lines[i].split(',');

        for (j = 0; j < fields.length; j++) {
            let fieldName = translations[fields[j]];
            if (fieldName != undefined) {
                obj[fieldName] = line[j];
            }
        }

        result.push(obj);
    }

    var resultDict = {};
    result.forEach(g => {
        var trimmedEmail = g.email.trim().toLowerCase()
        if (resultDict[trimmedEmail] == undefined) { resultDict[trimmedEmail] = []; }
        resultDict[trimmedEmail].push(g);
    })
    return resultDict;
}

function display(el, show) {
    if (show) {
        el.classList.remove("hide");
    } else {
        el.classList.add("hide")
    }
}

function displayId(id, show) {
    var e = document.getElementById(id);
    display(e, show);
}

function displayCls(cls, show) {
    var es = document.getElementsByClassName(cls);
    for (i = 0; i < es.length; i++) {
        display(es.item(i), show);
    }
}

function isIE() {
    var ua = window.navigator.userAgent; //Check the userAgent property of the window.navigator object
    var msie = ua.indexOf('MSIE '); // IE 10 or older
    var trident = ua.indexOf('Trident/'); //IE 11

    return (msie > 0 || trident > 0);
}

if (isIE()) {
    displayId("loading", false);
    displayId("login", false);
    displayId("notSupported", true);
} else {
    load();
}