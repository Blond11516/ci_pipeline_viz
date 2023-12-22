import ApexCharts from "apexcharts";
import { HookContext } from "../../types/hook";

const timelineChart = {
  mounted(this: HookContext) {
    const dataset = this.el.dataset as unknown as string;
    const series = JSON.parse(dataset) as { series: ApexAxisChartSeries };
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

export default timelineChart;
