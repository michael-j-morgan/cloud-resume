const storageKey = "cloud-resume-visit-count";

function addVisitorComment(visits) {
    document.body.appendChild(
        document.createComment(` Visitor count: ${visits} `)
    );
}

const existingCount = sessionStorage.getItem(storageKey);

if (existingCount) {
    addVisitorComment(existingCount);
} else {
    const apiUrl = new URL(
        "https://hztts5vqqk.execute-api.us-east-2.amazonaws.com/count"
    );

    const ref = new URLSearchParams(window.location.search).get("ref");

    if (ref) {
        apiUrl.searchParams.set("ref", ref);
    }

    fetch(apiUrl)
        .then((response) => {
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            return response.json();
        })
        .then((data) => {
            sessionStorage.setItem(storageKey, data.visits);
            addVisitorComment(data.visits);
        })
        .catch((error) => {
            console.error("Unable to record site visit:", error);
        });
}
