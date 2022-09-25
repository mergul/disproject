function myRouter(event, type) {
  event.preventDefault();
  window.history.pushState({}, "newUrl", event.currentTarget.href);
  recreateChart(type);
}
function recreateChart(type) {
  let chartStatus = Chart.getChart("myChart");
  if (chartStatus != undefined) {
    chartStatus.destroy();
  }
  const section = document.querySelector(".home-section");
  const config = type(section);
  let myChart, ctx;
  const canvas = document.getElementById("myChart");
  if (canvas) {
    ctx = canvas.getContext("2d");
    myChart = new Chart(ctx, config);
  }
}
function polarArea(section) {
  section.style.width = "calc(50% - 78px)";
  return {
    type: "polarArea",
    data: {
      labels: ["Red", "Green", "Yellow", "Grey", "Blue"],
      datasets: [
        {
          label: "My First Dataset",
          data: [11, 16, 7, 3, 14],
          backgroundColor: [
            "rgb(255, 99, 132)",
            "rgb(75, 192, 192)",
            "rgb(255, 205, 86)",
            "rgb(201, 203, 207)",
            "rgb(54, 162, 235)",
          ],
        },
      ],
    },
    options: {},
  };
}
function line(section) {
  section.style.width = "calc(100% - 78px)";
  return {
    type: "line",
    data: {
      labels: ["January", "February", "March", "April", "May", "June"],
      datasets: [
        {
          label: "My First dataset",
          backgroundColor: "rgb(255, 99, 132)",
          borderColor: "rgb(255, 99, 132)",
          data: [0, 10, 5, 2, 20, 30, 45],
        },
      ],
    },
    options: {},
  };
}
function bar(section) {
  section.style.width = "calc(100% - 78px)";
  return {
    type: "bar",
    data: {
      labels: ["Red", "Blue", "Yellow", "Green", "Purple", "Orange"],
      datasets: [
        {
          label: "# of Votes",
          data: [12, 19, 3, 5, 2, 3],
          backgroundColor: [
            "rgba(255, 99, 132, 0.2)",
            "rgba(54, 162, 235, 0.2)",
            "rgba(255, 206, 86, 0.2)",
            "rgba(75, 192, 192, 0.2)",
            "rgba(153, 102, 255, 0.2)",
            "rgba(255, 159, 64, 0.2)",
          ],
          borderColor: [
            "rgba(255, 99, 132, 1)",
            "rgba(54, 162, 235, 1)",
            "rgba(255, 206, 86, 1)",
            "rgba(75, 192, 192, 1)",
            "rgba(153, 102, 255, 1)",
            "rgba(255, 159, 64, 1)",
          ],
          borderWidth: 1,
        },
      ],
    },
    options: {
      scales: {
        y: {
          beginAtZero: true,
        },
      },
    },
  };
}
function doughnut(section) {
  section.style.width = "calc(50% - 78px)";
  return {
    type: "doughnut",
    data: {
      labels: ["Red", "Blue", "Yellow"],
      datasets: [
        {
          label: "My First Dataset",
          data: [300, 50, 100],
          backgroundColor: [
            "rgb(255, 99, 132)",
            "rgb(54, 162, 235)",
            "rgb(255, 205, 86)",
          ],
          hoverOffset: 4,
        },
      ],
    },
  };
}
window.addEventListener("load", (event) => {
  _injectScript(
    "https://unpkg.com/boxicons@2.0.7/css/boxicons.min.css",
    "link",
    true
  );
  getsScript(
    "chart",
    1,
    "https://cdn.jsdelivr.net/npm/chart.js",
    "script",
    "javascript",
    function () {
      console.log("chart-sidebar");
      ensureFooIsSet().then(() => {
        mySubject.next(true);
      });
    }
  );
});
window.addEventListener("popstate", function () {
  const uparts = document.location.href.split("/");
  if (uparts[uparts.length - 1] === "admin") {
    recreateChart(
      document.location.toString().includes("pageviews") ? bar : polarArea
    );
  }
});
