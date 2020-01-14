// TODO: compare lowercase email in login screen and show "unsupported browser" message for IE

var email, guests;
email = localStorage.getItem('email');

async function load() {
    // first get the guest list. Try session storage first.
    guests = sessionStorage.getItem('guests');
    if (guests == null) {
        var guestsCsvUrl = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vTny8qvPDcrGqPOxeHYIBJKJ2tbkkNCINWy3pdHhHzt12igcxjNeX6dcHscGETDBnWlrTCOhVILEcRS/pub?gid=0&single=true&output=csv';
        var guestsStr = await makeRequest('GET', guestsCsvUrl);
        guests = parseCsv(guestsStr);
        sessionStorage.setItem('guests', JSON.stringify(guests));
    } else {
        guests = JSON.parse(guests);
    }

    if (email != null) {
        // show login screen and get the email
    } else {
        showWebsite();
    }
}

function showWebsite() {
    function display(id, show) {
        var e = document.getElementById(id);
        if (show) {
            e.classList.remove("hide");
        } else {
            e.classList.add("hide")
        }
    }
    display("mainContent", true);
    display("loading", false);
    display("login", false);
    // also show/hide stuff based on the permissions in guests
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

function parseCsv(input) {
    var translations = {
        'Email': "email",
        'Invited to Boys Haldi': "boysHaldi",
        'Invited to chunni sagan': "chunniSagan",
        'Invited to civil': "civil",
        'Invited to mehndi': "mehndi",
        'Invited to reception': "reception",
        'Invited to temple': "temple",
        'Name': "name"
    }

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
        if (resultDict[g.email] == undefined) { resultDict[g.email] = []; }

        resultDict[g.email].push(g);
    })
    return resultDict;
}

load();