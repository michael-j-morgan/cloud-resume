fetch("https://hztts5vqqk.execute-api.us-east-2.amazonaws.com/count")
    .then((response) => {
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        return response.json();
    })
    .then((data) => {
        document.body.appendChild(
            document.createComment(` Visitor count: ${data.visits} `)
        );
    })
    .catch((error) => {
        console.error("Unable to record site visit:", error);
    });
