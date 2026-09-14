const counterElement = document.getElementById("visitor-count");

fetch("https://hztts5vqqk.execute-api.us-east-2.amazonaws.com/count")
    .then((response) => {
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        return response.json();
    })
    .then((data) => {
        counterElement.textContent = data.visits;
    })
    .catch((error) => {
        console.error("Unable to load visitor count:", error);
        counterElement.textContent = "unavailable";
    });
