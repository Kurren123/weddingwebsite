var btn = document.getElementById('submit');
btn.addEventListener('click', () => {
    btn.setAttribute('disabled', true);

    var xhr = new XMLHttpRequest();
    xhr.open("POST", 'https://script.google.com/macros/s/AKfycbwhamnhpgOJ3RyEAom3-KF3I0UEE7GmMtSDQoPBDyqtPQAV9b2U/exec', true);

    xhr.onreadystatechange = function () {
        btn.setAttribute('disabled', false);
        console.log(this);
        alert('done');
        if (this.readyState === XMLHttpRequest.DONE && this.status === 200) {

        }
    }

    body = {
        "Kurren Nischal": { "civil": true, "reception": false },
        "Neelam Nischal": { "civil": false, "reception": false }
    };

    //xhr.send(JSON.stringify(body));
});
