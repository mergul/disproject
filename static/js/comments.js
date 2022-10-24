document.addEventListener("DOMContentLoaded", function (event) {
  document
    .getElementById("js-commentForm")
    .addEventListener("submit", function (event) {
      event.preventDefault();
      var message = document.getElementById("js-createCommentTextarea").value;
      console.log("message -> ", message);
      // (Browsers that enforce the "required" attribute on the textarea won't see this alert)
      if (!message) {
        alert("Please fill out the comment form first.");
        return;
      }
      fetch("/comments", {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: message }),
      })
        .then((data) => data.json())
        .then((response) => {
          var newNode = document.createElement("li");
          newNode.innerText = response.message;
          console.log(response);
          document.getElementById("js-commentList").append(newNode);
        });
    });
});
