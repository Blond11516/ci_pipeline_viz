export default {
  mounted() {
    const series = JSON.parse(this.el.dataset.series);
    const chart = new ApexCharts(document.querySelector("#chart"), {
      series: series,
      chart: {
        height: 350,
        type: "rangeBar",
      },
      plotOptions: {
        bar: {
          horizontal: true,
          rangeBarGroupRows: true,
        },
      },
      xaxis: {
        type: "numeric",
        min: 0,
      },
      tooltip: {
        enabled: false,
      },
    });
    chart.render();
  },
};
